defmodule MicroServer.LuaLib.Table do
  alias MicroServer.LuaUtility
  # alias MicroServer.ServerUtility
  @doc """
  过程数据初始化函数, 在第一次获取过程数据的时候调用
  """
  @spec init_state :: map
  def init_state, do: %{}

  @doc """
  模块需要用到的lua脚本
  """
  def addtion_lua, do: ""

  @doc """
  库初始化函数, 在启动微服务的时候调用
  """
  @spec init(lua_state :: term, String.t(), integer) :: new_lua_state :: term
  def init(lua_state, _app_id, _server_id) do
    lua_state
    |> LuaUtility.set_value([:system], [])
    |> is_in?()
    |> clone()
  end

  @doc """
  # 例子
      -- true
      table.is_in(3, {2,4,6,3})
      -- true
      table.is_in("name", "Max", {name="Max"})
  """
  def is_in?(lua_state) do
    LuaUtility.set_value(lua_state, [:table, :is_in], fn datas, state ->
      result =
        case datas do
          [k, v, table] ->
            table
            |> Enum.any?(fn {key, value} ->
              key == k && value == v
            end)

          [v, table] ->
            table
            |> Enum.any?(fn {_key, value} ->
              value == v
            end)
        end

      {[result], state}
    end)
  end

  @doc """
  # 例子
      local new_t = table.clone({2,4,6,3})
  """
  def clone(lua_state) do
    LuaUtility.set_value(lua_state, [:table, :clone], fn [t], state ->
      {[t], state}
    end)
  end
end
