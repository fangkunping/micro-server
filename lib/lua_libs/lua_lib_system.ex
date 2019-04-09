defmodule MicroServer.LuaLib.System do
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
  end
end
