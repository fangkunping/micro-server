defmodule MicroServer.LuaLib.Cache1 do
  @doc """
  用于服务器之间共享的高速缓存
  """
  alias MicroServer.LuaUtility
  alias Kunerauqs.EtsProxy

  @spec init_state :: map
  def init_state,
    do: %{
      cache1_table: %{},
      cache1_def_query: %{}
    }

  @doc """
  模块需要用到的lua脚本
  """
  def addtion_lua do
    ~s|
      __CACHE_LEVEL1_EACH_F = nil
      cache1 = cache1 or {}
      function cache1.map(f)
        __CACHE_LEVEL1_EACH_F = f
        return cache1.map_run()
      end

      function cache1.map_run1(key, value)
        return __CACHE_LEVEL1_EACH_F(key, value)
      end
    |
  end

  @doc """
  库初始化函数, 在启动微服务的时候调用
  """
  @spec init(lua_state :: term, String.t(), integer) :: new_lua_state :: term
  def init(lua_state, app_id, server_id) do
    app_id_atom = app_id |> String.to_atom()

    lua_state
    |> level1_write(app_id_atom)
    |> level1_read(app_id_atom)
    |> level1_delete(app_id_atom)
    |> level1_map(app_id_atom)
    |> level1_size(app_id_atom)
    |> level1_q_write(app_id_atom, server_id)
    |> level1_q_read(app_id_atom, server_id)
    |> level1_q_select(app_id_atom, server_id)
    |> level1_q_select_and_update(app_id_atom, server_id)
    |> level1_q_delete(app_id_atom, server_id)
  end

  @doc """
  写入 level1 缓存(以ets的形式)

  ## 格式

      cache1.q_write(table_name :: string, rows :: table) :: true | false

  ## 说明

    如果 返回false 说明缓存已经满了 或 table没有定义

  ## 例子

      cache1.q_write("test", {name=Max})
  """
  def level1_q_write(lua_state, app_id, server_id) do
    LuaUtility.set_value(lua_state, [:cache1, :q_write], fn [table_name, rows], state ->
      # 获取过程数据
      process_state = MicroServer.LuaLibUtility.fetch_state(server_id, __MODULE__)
      cache1_table = process_state.cache1_table
      rows = LuaUtility.table_to_map(rows)

      if cache1_table |> Map.has_key?(table_name) do
        data =
          cache1_table[table_name].rows_string
          |> Enum.map(fn k ->
            rows |> Map.get(k)
          end)
          |> List.to_tuple()

        result = set_level1_cache(app_id, data)
        {[result], state}
      else
        {[false], state}
      end
    end)
  end

  @doc """
  读取 level1 缓存(以ets的形式)

  ## 格式

      cache1.q_read(table_name :: string, key :: any) :: any | nil

  ## 例子

      cache1.q_read("test", 10)
  """
  def level1_q_read(lua_state, app_id, server_id) do
    LuaUtility.set_value(lua_state, [:cache1, :q_read], fn [table_name, key], state ->
      case EtsProxy.read_raw(app_id, LuaUtility.table_to_map(key)) do
        nil ->
          {[nil], state}

        all ->
          # 获取过程数据
          process_state = MicroServer.LuaLibUtility.fetch_state(server_id, __MODULE__)
          cache1_table = process_state.cache1_table

          if cache1_table |> Map.has_key?(table_name) do
            result = List.zip([cache1_table[table_name].rows_tuple_string, all])

            {[result], state}
          else
            {[nil], state}
          end
      end
    end)
  end

  def level1_q_select(lua_state, app_id, server_id) do
    LuaUtility.set_value(lua_state, [:cache1, :q_select], fn [query_id | values], state ->
      {rows_tuple_string, ms} = get_ms(server_id, query_id, values)

      result =
        :ets.select(app_id, ms)
        |> Enum.map(fn rs ->
          List.zip([rows_tuple_string, rs])
        end)

      {[result], state}
    end)
  end

  def level1_q_select_and_update(lua_state, app_id, server_id) do
    LuaUtility.set_value(lua_state, [:cache1, :q_select_and_update], fn [
                                                                          query_id,
                                                                          update_obj | values
                                                                        ],
                                                                        state ->
      {rows_tuple_string, ms} = get_ms(server_id, query_id, values)

      result =
        :ets.select(app_id, ms)
        |> Enum.map(fn rs ->
          data =
            update_obj
            |> Enum.reduce(List.zip([rows_tuple_string, rs]), fn {k, _} = e, acc ->
              acc |> List.keyreplace(k, 0, e)
            end)
            |> Enum.unzip()
            |> elem(1)
            |> List.to_tuple()

          EtsProxy.write(app_id, data)
        end)

      {[result], state}
    end)
  end

  def level1_q_delete(lua_state, app_id, server_id) do
    LuaUtility.set_value(lua_state, [:cache1, :q_delete], fn [query_id | values], state ->
      {_, ms} = get_ms(server_id, query_id, values, true)
      result = :ets.select_delete(app_id, ms)
      {[result], state}
    end)
  end

  def get_ms(server_id, query_id, values, ret \\ :"$_") do
    # 获取过程数据
    process_state = MicroServer.LuaLibUtility.fetch_state(server_id, __MODULE__)
    cache1_table = process_state.cache1_table
    cache1_def_query = process_state.cache1_def_query
    table_name = cache1_def_query[query_id].table_name

    rows_tuple_string = cache1_table[table_name].rows_tuple_string

    ms =
      if ret == true do
        # 删除使用 gen_match_spec2 可以删除不同长度的row
        gen_match_spec2(cache1_table, cache1_def_query, query_id, values, ret)
      else
        # 选择也可用 gen_match_spec2
        gen_match_spec(cache1_table, cache1_def_query, query_id, values, ret)
      end

    {rows_tuple_string, ms}
  end

  @doc """
  写入 level1 缓存

  ## 格式

      cache1.write(key :: any, value :: any) :: true | false

  ## 说明

    如果 返回false 说明缓存已经满了

  ## 例子

      cache1.write("test", {name=Max})
  """
  def level1_write(lua_state, app_id) do
    LuaUtility.set_value(lua_state, [:cache1, :write], fn [key, value], state ->
      result = set_level1_cache(app_id, key, value)
      {[result], state}
    end)
  end

  @doc """
  读取 level1 缓存, 其它说明见 cache1.write
      cache1.read(key :: any) :: any | nil
      cache1.read("test")
  """
  def level1_read(lua_state, app_id) do
    LuaUtility.set_value(lua_state, [:cache1, :read], fn [key], state ->
      result = get_level1_cache(app_id, key)
      {[result], state}
    end)
  end

  @doc """
  删除 level1 对应键值 或 删除所有值

      cache1.delete()
      cache1.delete("test")
  """

  def level1_delete(lua_state, app_id) do
    LuaUtility.set_value(lua_state, [:cache1, :delete], fn
      [], state ->
        clear_level1_cache(app_id)
        {[], state}

      [key], state ->
        delete_level1_cache(app_id, key)
        {[], state}
    end)
  end

  @doc """
  遍历整个表,

  ## 格式

      cache1.map(f :: function) :: list

      f = function(key, value) :: true | true, result | false, result

  ## 说明

    - 首先定义一个函数, 将函数传入 cache1.map, 得到结果
    - 该函数是一个闭包, 里面的修改对上下文没有任何影响
    - 函数返回意义:
      * true: 继续遍历
      * false: 终止遍历
      * true, result: 继续遍历, 并将result加入 返回列表
      * false, result: 终止遍历, 并将result加入 返回列表

  ## 例子

      function on_http(tick, ...)
        cache1.write("a", 10.12)
        cache1.write("b", 10)
        cache1.write("c", {1,2,3,4})
        trace(cache1.map(
          function(key, value)
            trace(key, value)
            if (key == "a") then
              return false, value
            else
              return true
            end
          end
        )[1])
        return
      end
  """
  def level1_map(lua_state, app_id) do
    LuaUtility.set_value(lua_state, [:cache1, :map_run], fn [], state ->
      {_, result} =
        :ets.foldl(
          fn
            {key, value}, {:cont, acc} ->
              case LuaUtility.call(state, [:cache1, :map_run1], [key, value]) do
                {[true], _} ->
                  {:cont, acc}

                {[true, result], _} ->
                  {:cont, [result | acc]}

                {[false], _} ->
                  {:halt, acc}

                {[false, result], _} ->
                  {:halt, [result | acc]}

                {:error, _reason} ->
                  exit({MicroServer.LuaLib.Cache1, :level1_map_error})
              end

            _, any ->
              any
          end,
          {:cont, []},
          app_id
        )

      {[result], state}
    end)
  end

  @doc """
  记录条数
  """
  def level1_size(lua_state, app_id) do
    LuaUtility.set_value(lua_state, [:cache1, :size], fn [], state ->
      result = EtsProxy.size(app_id)

      {[result], state}
    end)
  end

  defp get_level1_cache(app_id, key) do
    EtsProxy.read!(app_id, key, nil)
  end

  defp set_level1_cache(app_id, key, value) do
    set_level1_cache(app_id, {key, value})
  end

  defp set_level1_cache(app_id, data) do
    level1_cache_size = EtsProxy.memory(app_id)
    cache_conf = apply(MicroServer.Runtime.Config, :lua, []).lib_conf[__MODULE__]

    if level1_cache_size > cache_conf.level1_cache_size do
      false
    else
      EtsProxy.write(app_id, data)
      true
    end
  end

  defp delete_level1_cache(app_id, key) do
    EtsProxy.delete(app_id, key)
  end

  defp clear_level1_cache(app_id) do
    EtsProxy.clear(app_id)
  end

  @doc """
  为cache1 加入过程数据
  """
  def add_process_state(scripts, server_id) do
    scripts
    |> Enum.each(fn script ->
      case MicroServer.LuaParserUtility.parse(script.content) do
        {:ok, parser} ->
          cache1_table = MicroServer.LuaParserUtility.get_cache1_table(parser)
          cache1_def_query = MicroServer.LuaParserUtility.get_cache1_def_query(parser)

          process_state = MicroServer.LuaLibUtility.fetch_state(server_id, __MODULE__)
          cache1_table_old = process_state.cache1_table
          cache1_def_query_old = process_state.cache1_def_query

          MicroServer.LuaLibUtility.store_state(server_id, __MODULE__, %{
            process_state
            | cache1_table: Map.merge(cache1_table_old, cache1_table),
              cache1_def_query: Map.merge(cache1_def_query_old, cache1_def_query)
          })

        {:parse_error, error_line} ->
          {:halt,
           {:error, "something wrong on line #{error_line} [#{script.name}][#{script.note}]!"}}

        {:scan_error, error_line} ->
          {:halt,
           {:error, "something wrong on line #{error_line} [#{script.name}][#{script.note}]!"}}
      end
    end)
  end

  @doc """
  创建用于查询的Match Specifications
  """
  def gen_match_spec(cache1_table, cache1_def_query, query_id, values, ret \\ :"$_") do
    query = cache1_def_query |> Map.get(query_id)
    table_name = query.table_name
    table_rows = cache1_table[table_name][:row_name_index]
    q1 = cache1_table[table_name][:q1]

    query.conditions
    |> Enum.map(fn c ->
      {q1,
       c
       |> Enum.map(fn {op, row_name, value_num} ->
         {op, table_rows[row_name], :lists.nth(value_num, values)}
       end), [ret]}
    end)
  end

  def gen_match_spec2(cache1_table, cache1_def_query, query_id, values, ret \\ :"$_") do
    query = cache1_def_query |> Map.get(query_id)
    table_name = query.table_name
    table_rows = cache1_table[table_name][:row_name_index2]

    query.conditions
    |> Enum.map(fn c ->
      {:"$1",
       c
       |> Enum.map(fn {op, row_name, value_num} ->
         {op, {:element, table_rows[row_name], :"$1"}, :lists.nth(value_num, values)}
       end), [ret]}
    end)
  end
end
