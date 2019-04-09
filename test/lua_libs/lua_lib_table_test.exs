defmodule MicroServerTest.LuaLib.TableTest do
  use MicroServerTest.MyCase, async: false

  setup_all do
    lua_script = ~s|
      local action = {}

      function on_http(ticket, message)
        return action[message.c](message)
      end

      action.is_in1 = function()
        return table.is_in(3, {2,4,6,3})
      end

      action.is_in2 = function()
        return table.is_in("name", "Max", {name="Max"})
      end

      action.is_in3 = function()
        return table.is_in(7, {2,4,6,3})
      end

      action.is_in4 = function()
        return table.is_in("name", "Max2", {name="Max"})
      end

      action.clone = function()
        local t = {2,4,6,3}
        local new_t = table.clone({2,4,6,3})
        new_t[1] = 1
        local t2 = t
        t2[1] = 0
        return new_t[1], t[1], t2[1]
      end
    |
    MicroServer.Repo.query!(~s/update `scripts` set `content` = '#{lua_script}' where id = 1/)
    start_server()
    :ok
  end

  test "is_in1" do
    [result] = MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "is_in1"}})
    assert result == true
  end

  test "is_in2" do
    [result] = MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "is_in2"}})
    assert result == true
  end

  test "is_in3" do
    [result] = MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "is_in3"}})
    assert result == false
  end

  test "is_in4" do
    [result] = MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "is_in4"}})
    assert result == false
  end

  test "clone" do
    result = MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "clone"}})
    assert result == [1, 0, 0]
  end
end
