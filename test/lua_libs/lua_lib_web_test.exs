defmodule MicroServerTest.LuaLib.WebTest do
  use MicroServerTest.MyCase, async: false

  setup_all do
    lua_script = ~s|
      require(web)
      local action = {}

      function on_http(ticket, message)
        return action[message.c](message)
      end

      action.url_encode = function()
        return web.url_encode({
          name="Max",
          age=40
        })
      end

    |
    MicroServer.Repo.query!(~s/update `scripts` set `content` = '#{lua_script}' where id = 1/)
    start_server()
    :ok
  end

  test "url_encode" do
    [result] =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "url_encode"}})

    assert result == "age=40&name=Max"
  end
end
