defmodule MicroServer.Minds do
  @moduledoc """
  lua 对外接口
    on_init()
    on_tick()

  每次运行tick之前,都要准备好
      MESSAGES = {}
      UPTIME = 0
      DELTA_TIME = 0

  message 原始信息结构
    {:http, map}
    {:websocket, map}

    :http -> CONST_HTTP = 1
    :websocket -> CONST_WEBSOCKET = 2

  """
  @type lua_table :: term
  @const_http 1
  @const_websocket 2
  @spec trans_to_lua_message(list) :: lua_table
  def trans_to_lua_message(messages) when is_list(messages) do
    messages
    |> Enum.reverse()
    |> Enum.map(fn
      {:http, m} ->
        [{1, @const_http}, {2, MicroServer.LuaUtility.map_to_table(m)}]

      {:websocket, m} ->
        [{1, @const_websocket}, {2, MicroServer.LuaUtility.map_to_table(m)}]
    end)
  end

  @spec trans_to_lua_message({:http, map}) :: lua_table
  def trans_to_lua_message({:http, message}) do
    [{1, @const_http}, {2, MicroServer.LuaUtility.map_to_table(message)}]
  end

  @spec trans_to_lua_message({:http, map}) :: lua_table
  def trans_to_lua_message({:websocket, message}) do
    [{1, @const_websocket}, {2, MicroServer.LuaUtility.map_to_table(message)}]
  end
end
