defmodule MicroServerTest.LuaLib.CacheTest do
  use MicroServerTest.MyCase, async: false

  setup_all do
    lua_script = ~s|
      require(cache1,cache2)
      local action = {}

      function on_http(ticket, message)
        return action[message.c](message)
      end

      action.cache1 = function()
        cache1.write("a", 10.12)
        cache1.write("b", 10)
        cache1.write("c", {1,2,3,4})
        -- 结果是 10.12
        local result = cache1.map(
          function(key, value)
            trace(key, value)
            if key == "a" then
              return false, value
            else
              return true
            end
          end
        )[1]
        return result
      end

      action.cache2 = function()
        cache2.delete()
        cache2.write("a", 10.12)
        cache2.write("b", 10)
        cache2.write("c", {1,2,3,4})
        -- 结果是 10.12
        local result = cache2.map(
          function(key, value)
            trace(key, value)
            if (key == "a") then
              return false, value
            else
              return true
            end
          end
        )[1]
        return result
      end
    |
    MicroServer.Repo.query!(~s/update `scripts` set `content` = '#{lua_script}' where id = 1/)
    start_server()
    :ok
  end

  test "cache1" do
    [result] = MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "cache1"}})
    assert result == 10.12
  end

  test "cache2" do
    [result] = MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "cache2"}})
    assert result == 10.12
  end

end
