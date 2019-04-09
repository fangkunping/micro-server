defmodule MicroServer.LuaLib.Cache2 do
  @moduledoc """
  用于服务器之间共享的文件缓存
  """
  alias MicroServer.LuaUtility
  alias Kunerauqs.DetsProxy

  @doc """
  过程数据初始化函数, 在第一次获取过程数据的时候调用
  """
  @spec init_state :: map
  def init_state, do: %{}

  @doc """
  模块需要用到的lua脚本
  """
  def addtion_lua do
    ~s|
      __CACHE_LEVEL2_EACH_F = nil
      cache2 = cache2 or {}
      function cache2.map(f)
        __CACHE_LEVEL2_EACH_F = f
        return cache2.map_run()
      end

      function cache2.map_run1(key, value)
        return __CACHE_LEVEL2_EACH_F(key, value)
      end
    |
  end

  @doc """
  库初始化函数, 在启动微服务的时候调用
  """
  @spec init(lua_state :: term, String.t(), integer) :: new_lua_state :: term
  def init(lua_state, app_id, server_id) do
    conf = apply(MicroServer.Runtime.Config, :lua, []).lib_conf[__MODULE__]

    if DetsProxy.init_ram(app_id, conf.level2_cache_path <> "#{app_id}.cache") == false do
      exit({MicroServer.LuaLib.Cache2, :init_error})
    end

    lua_state
    |> level2_write(app_id)
    |> level2_read(app_id)
    |> level2_delete(app_id)
    |> level2_map(app_id)
    |> level2_size(app_id)
    |> level2_q_write(app_id, server_id)
    |> level2_q_read(app_id, server_id)
    |> level2_q_select(app_id, server_id)
    |> level2_q_delete(app_id, server_id)
  end

  @doc """
  写入 level2 缓存(以ets的形式)

  ## 格式

      cache2.q_write(table_name :: string, rows :: table) :: true | false

  ## 说明

    如果 返回false 说明缓存已经满了 或 table没有定义

  ## 例子

      cache2.q_write("test", {name=Max})
  """
  def level2_q_write(lua_state, app_id, server_id) do
    LuaUtility.set_value(lua_state, [:cache2, :q_write], fn [table_name, rows], state ->
      # 获取过程数据
      process_state = MicroServer.LuaLibUtility.fetch_state(server_id, MicroServer.LuaLib.Cache1)
      cache1_table = process_state.cache1_table
      rows = LuaUtility.table_to_map(rows)

      if cache1_table |> Map.has_key?(table_name) do
        data =
          cache1_table[table_name].rows_string
          |> Enum.map(fn k ->
            rows |> Map.get(k)
          end)
          |> List.to_tuple()

        result = set_level2_cache(app_id, data)
        {[result], state}
      else
        {[false], state}
      end
    end)
  end

  @doc """
  读取 level2 缓存(以ets的形式)

  ## 格式

      cache2.q_read(table_name :: string, key :: any) :: any | nil

  ## 例子

      cache2.q_read("test", 10)
  """
  def level2_q_read(lua_state, app_id, server_id) do
    LuaUtility.set_value(lua_state, [:cache2, :q_read], fn [table_name, key], state ->
      case DetsProxy.read_raw(app_id, LuaUtility.table_to_map(key)) do
        nil ->
          {[nil], state}

        all ->
          # 获取过程数据
          process_state =
            MicroServer.LuaLibUtility.fetch_state(server_id, MicroServer.LuaLib.Cache1)

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

  def level2_q_select(lua_state, app_id, server_id) do
    LuaUtility.set_value(lua_state, [:cache2, :q_select], fn [query_id | values], state ->
      {rows_tuple_string, ms} = MicroServer.LuaLib.Cache1.get_ms(server_id, query_id, values)

      result =
        :dets.select(app_id, ms)
        |> Enum.map(fn rs ->
          List.zip([rows_tuple_string, rs])
        end)

      {[result], state}
    end)
  end

  def level2_q_delete(lua_state, app_id, server_id) do
    LuaUtility.set_value(lua_state, [:cache2, :q_delete], fn [query_id | values], state ->
      {_, ms} =
        MicroServer.LuaLib.Cache1.get_ms(server_id, query_id, values, true)

      result = :dets.select_delete(app_id, ms)
      {[result], state}
    end)
  end

  @doc """
  写入 level2 缓存

  ## 格式

      cache2.write(key :: any, value :: any) :: true | false

  ## 说明

    如果 返回false 说明缓存已经满了

  ## 例子

      cache2.write("test", {name=Max})
  """
  def level2_write(lua_state, app_id) do
    LuaUtility.set_value(lua_state, [:cache2, :write], fn [key, value], state ->
      result = set_level2_cache(app_id, key, value)
      {[result], state}
    end)
  end

  @doc """
  读取 level2 缓存, 其它说明见 cache2.write
      cache2.read(key :: any) :: any | nil
      cache2.read("test")
  """
  def level2_read(lua_state, app_id) do
    LuaUtility.set_value(lua_state, [:cache2, :read], fn [key], state ->
      result = get_level2_cache(app_id, key)
      {[result], state}
    end)
  end

  @doc """
  删除 level2 对应键值 或 删除所有值

      cache2.delete()
      cache2.delete("test")
  """

  def level2_delete(lua_state, app_id) do
    LuaUtility.set_value(lua_state, [:cache2, :delete], fn
      [], state ->
        clear_level2_cache(app_id)
        {[], state}

      [key], state ->
        delete_level2_cache(app_id, key)
        {[], state}
    end)
  end

  @doc """
  遍历整个表,

  ## 格式

      cache2.map(f :: function) :: list

      f = function(key, value) :: true | true, result | false, result

  ## 说明

    - 首先定义一个函数, 将函数传入 cache2.map, 得到结果
    - 该函数是一个闭包, 里面的修改对上下文没有任何影响
    - 函数返回意义:
      * true: 继续遍历
      * false: 终止遍历
      * true, result: 继续遍历, 并将result加入 返回列表
      * false, result: 终止遍历, 并将result加入 返回列表

  ## 例子

      function on_http(tick, ...)
        cache2.write("a", 10.12)
        cache2.write("b", 10)
        cache2.write("c", {1,2,3,4})
        trace(cache2.map(
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
  def level2_map(lua_state, app_id) do
    LuaUtility.set_value(lua_state, [:cache2, :map_run], fn [], state ->
      result =
        :dets.traverse(app_id, fn {key, value} ->
          case LuaUtility.call(state, [:cache2, :map_run1], [key, value]) do
            {[true], _} ->
              :continue

            {[true, result], _} ->
              {:continue, result}

            {[false], _} ->
              {:done, nil}

            {[false, result], _} ->
              {:done, result}

            {:error, _reason} ->
              exit({MicroServer.LuaLib.Cache2, :level2_map_error})
          end
        end)

      result =
        case result do
          [nil | result] -> result
          _ -> result
        end

      {[result], state}
    end)
  end

  @doc """
  记录条数
  """
  def level2_size(lua_state, app_id) do
    LuaUtility.set_value(lua_state, [:cache2, :size], fn [], state ->
      result = DetsProxy.size(app_id)

      {[result], state}
    end)
  end

  defp get_level2_cache(app_id, key) do
    DetsProxy.read!(app_id, key, nil)
  end

  defp set_level2_cache(app_id, key, value) do
    set_level2_cache(app_id, {key, value})
  end

  defp set_level2_cache(app_id, data) do
    level2_cache_size = DetsProxy.file_size(app_id)
    cache_conf = apply(MicroServer.Runtime.Config, :lua, []).lib_conf[__MODULE__]

    if level2_cache_size > cache_conf.level2_cache_size do
      false
    else
      DetsProxy.write(app_id, data)
      DetsProxy.flush(app_id)
      true
    end
  end

  defp delete_level2_cache(app_id, key) do
    DetsProxy.delete(app_id, key)
    DetsProxy.flush(app_id)
  end

  defp clear_level2_cache(app_id) do
    DetsProxy.clear(app_id)
    DetsProxy.flush(app_id)
  end
end
