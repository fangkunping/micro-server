defmodule MicroServer.LuaLib.Websocket do
  alias MicroServer.LuaUtility
  alias MicroServer.ServerUtility

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
      function on_websocket(ticket, data)
      end
      function on_websocket_open(ticket, params)
        return true
      end
      function on_websocket_close(ticket)
      end
      function on_websocket_connect(ticket, params)
        return true
      end
      function on_websocket_disconnect(ticket)
      end
    |
  end

  @doc """
  库初始化函数, 在启动微服务的时候调用
  """
  @spec init(lua_state :: term, String.t(), integer) :: new_lua_state :: term
  def init(lua_state, _app_id, server_id) do
    lua_state
    |> LuaUtility.set_value([:websocket], [])
    |> send_to(server_id)
  end

  @doc """
  向对应的tick 或 tick列表传输数据

  ## lua 示例

      websocket.send(1, "hello world")
      websocket.send({1,2}, {name="Max"})
  """
  def send_to(lua_state, server_id) do
    LuaUtility.set_value(lua_state, [:websocket, :send], fn [ticks, data], state ->
      send_message = MicroServer.LuaLib.StringTools.pre_json_encode(data)
      ServerUtility.cast(server_id, {:add_send_queue, ticks, send_message})
      {[], state}
    end)
  end
end
