defmodule MicroServer.LuaLib.Mysql do
  alias MicroServer.LuaUtility
  alias MicroServer.LuaLibUtility
  alias MicroServer.CommonUtility

  @doc """
  过程数据初始化函数, 在第一次获取过程数据的时候调用
  """
  @spec init_state :: map
  def init_state do
    %{
      conn_keyword: nil,
      conn: nil
    }
  end

  @doc """
  模块需要用到的lua脚本
  """
  def addtion_lua, do: ""

  @doc """
  库初始化函数, 在启动微服务的时候调用
  """
  @spec init(lua_state :: term, String.t(), integer) :: new_lua_state :: term
  def init(lua_state, _app_id, server_id) do
    lua_state
    |> LuaUtility.set_value([:mysql], [])
    |> connect_db(server_id)
    |> query(server_id)
  end

  @doc """
  建立数据库连接
  """
  def connect_db(lua_state, server_id) do
    LuaUtility.set_value(lua_state, [:mysql, :connect], fn [conn_keyword], state ->
      conn_keyword =
        conn_keyword
        |> Enum.map(fn
          {"port", v} ->
            {:port, v |> KunERAUQS.D0_f.number_to_int()}

          {k, v} ->
            {k |> String.to_atom(), v}
        end)

      get_conn(server_id, conn_keyword)
      {[true], state}
    end)
  end

  @doc """
  执行语句

  ## 测试用
      test_mysql_conn = MicroServer.LuaLib.Mysql.get_conn(1)
      Mariaex.query(test_mysql_conn, "delete from web_user_stock_time where user_id=? and exp_time < ?", [957, 1545795295])

  """
  def query(lua_state, server_id) do
    LuaUtility.set_value(lua_state, [:mysql, :query], fn [sql | params], state ->
      conn = get_conn(server_id)
      # params =
      #  params
      #  |> Enum.map(fn e ->
      #    MicroServer.LuaLib.StringTools.format_number(e)
      #  end)
      #  |> IO.inspect()

      case Mariaex.query(conn, sql, params) do
        {:ok, result} ->
          result = Map.from_struct(result) |> Map.delete(:connection_id)
          columns = result.columns

          row_datas =
            case result.rows do
              nil ->
                []

              _ ->
                result.rows
                |> Enum.reduce([], fn row, row_datas ->
                  row =
                    row
                    |> Enum.map(fn
                      {{y, m, d}, {h, min, s, _}} ->
                        %DateTime{
                          year: y,
                          month: m,
                          day: d,
                          zone_abbr: "CET",
                          hour: h,
                          minute: min,
                          second: s,
                          microsecond: {0, 0},
                          utc_offset: 0,
                          std_offset: 0,
                          time_zone: "UTC"
                        }
                        |> DateTime.to_unix()

                      field ->
                        field
                    end)

                  [Enum.zip(columns, row) | row_datas]
                end)
            end

          {[
             [
               {"num_rows", result.num_rows},
               {"last_insert_id", result.last_insert_id},
               {"row_datas", row_datas}
             ]
           ], state}

        e ->
          e |> IO.inspect()
          LuaUtility.throw_lib_lua_error("mysql query error")
          {[], state}
      end
    end)
  end

  def get_conn(server_id, conn_keyword \\ nil) do
    process_state = LuaLibUtility.fetch_state(server_id, __MODULE__)
    conn = process_state.conn
    conn_keyword = conn_keyword || process_state.conn_keyword

    case conn_keyword do
      nil ->
        LuaUtility.throw_lib_lua_error("mysql connect params error")

      _ ->
        # conn_keyword = [{:backoff_type, :stop} | conn_keyword]

        conn =
          if CommonUtility.pid_alive?(conn) do
            conn
          else
            case Mariaex.start_link([{:datetime, :tuples}, {:backoff_type, :stop} | conn_keyword]) do
              {:ok, p} ->
                p

              _ ->
                LuaUtility.throw_lib_lua_error("mysql connect error")
            end
          end

        LuaLibUtility.store_state(server_id, __MODULE__, %{
          process_state
          | conn: conn,
            conn_keyword: conn_keyword
        })

        conn
    end
  end
end
