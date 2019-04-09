defmodule MicroServerTest.LuaScript.RequireTest do
  use MicroServerTest.MyCase, async: false

  setup_all do
    lua_script = ~s|
    require(crypto, string_tools)

    function on_http(ticket, message)
      trace(string_tools.join_with("_", 1,2,3.1,400000000000000))
      return crypto.password_hash("12345")
    end

    |
    MicroServer.Repo.query!(~s/update `scripts` set `content` = '#{lua_script}' where id = 1/)
    start_server()
    :ok
  end

  test "require" do
    MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{}}) |> IO.inspect()
    Process.sleep(@waiting_print_finish)
  end


end
