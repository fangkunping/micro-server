defmodule MicroServer.LuaLib.Web do
  alias MicroServer.LuaUtility
  alias MicroServer.LuaLibUtility
  alias MicroServer.CommonUtility

  require MicroServer.LuaConst
  MicroServer.LuaConst.create()

  @doc """
  过程数据初始化函数, 在第一次获取过程数据的时候调用
  """
  @spec init_state :: map
  def init_state() do
    %{
      http_request_interval:
        apply(MicroServer.Runtime.Config, :lua, []).lib_conf[__MODULE__].http_request_interval,
      next_http_request_time: 0
    }
  end

  @doc """
  模块需要用到的lua脚本
  """
  def addtion_lua do
    ~s|
      function on_http(ticket, data)
        return "ok"
      end
    |
  end

  @doc """
  库初始化函数, 在启动微服务的时候调用
  """
  @spec init(lua_state :: term, String.t(), integer) :: new_lua_state :: term
  def init(lua_state, _app_id, server_id) do
    lua_state
    |> LuaUtility.set_value([:web], [])
    |> http_get(server_id)
    |> http_post(server_id)
    |> http_url_encode()
  end

  @doc """
  get 方式获得 http 请求数据

  ## lua 使用

      web.http_get("http://xxx.xxx", {name="Max"})
      web.http_get("https://xxx.xxx", {name="Max"})
      web.http_get("http://xxx.xxx")
      web.http_get("https://xxx.xxx")

  ## 返回 以下4种类型

    - 返回数据
    - 404
    - nil 访问网站出错
    - "vip limit" vip 使用限制

  """
  def http_get(lua_state, server_id) do
    LuaUtility.set_value(lua_state, [:web, :http_get], fn pass_params, state ->
      if can_do?(server_id, :http_request) do
        uri =
          case pass_params do
            [uri] ->
              uri

            [uri, params] ->
              "#{uri}?#{URI.encode_query(params)}"
          end
        response = get_http(uri |> String.trim(), :get, nil)
        {[response], state}
      else
        {[@lib_vip_limit], state}
      end
    end)
  end

  @doc """
  post 方式获得 http 请求数据

  ## lua 使用

      web.http_post("http://xxx.xxx", {name="Max"})
      web.http_post("https://xxx.xxx", {name="Max"})
      web.http_post("http://xxx.xxx")
      web.http_post("https://xxx.xxx")

  ## 返回 以下4种类型

    - 返回数据
    - 404
    - nil 访问网站出错
    - "vip limit" vip 使用限制

  """
  def http_post(lua_state, server_id) do
    LuaUtility.set_value(lua_state, [:web, :http_post], fn pass_params, state ->
      if can_do?(server_id, :http_request) do
        {uri, params} =
          case pass_params do
            [uri] ->
              {uri, {}}

            [uri, params] ->
              {uri,
               params
               |> Enum.map(fn {k, v} ->
                 {"#{k}", "#{v}"}
               end)}
          end

        response = get_http(uri |> String.trim(), :post, params)
        {[response], state}
      else
        {[@lib_vip_limit], state}
      end
    end)
  end

  @doc """
  web.url_encode(table) -> string
  """
  def http_url_encode(lua_state) do
    LuaUtility.set_value(lua_state, [:web, :url_encode], fn [query_table], state ->
      result =
        try do
          LuaUtility.table_to_map(query_table) |> URI.encode_query()
        rescue
          # 捕获一般性错误
          _ -> nil
        catch
          # 捕获 抛出错误(使用throw函数), exit, error 错误
          _ -> nil
          _, _ -> nil
        end

      {[result], state}
    end)
  end

  defp get_http(uri, method, params) do
    CommonUtility.pool_call(:lua_lib_http_worker, {:http, uri, method, params})
  end

  # 根据过程数据,判断可否执行
  defp can_do?(server_id, :http_request) do
    state = LuaLibUtility.fetch_state(server_id, __MODULE__)
    now_time_stamp = CommonUtility.timestamp_ms()
    next_http_request_time = state.next_http_request_time

    if now_time_stamp > next_http_request_time do
      LuaLibUtility.store_state(server_id, __MODULE__, %{
        state
        | next_http_request_time: now_time_stamp + state.http_request_interval
      })

      true
    else
      false
    end
  end
end
