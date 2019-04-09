defmodule MicroServerTest.LuaLib.BasicTest do
  use MicroServerTest.MyCase, async: false

  setup_all do
    lua_script = ~s|
      local action = {}

      function on_http(ticket, message)
        return action[message.c](message)
      end

      action.print1 = function()
        print("this is print1 test!")
        return ""
      end

      action.print2 = function()
        print(1, "this is print2 test!", 3, {a=100, b=200})
        return ""
      end

      -- false, {code=1001}
      action.pcall1 = function()
          local state, result = pcall(function()
              error({code=1001})
          end)
        return result.code
      end

      -- false
      action.pcall2 = function()
        return pcall(function()
            local test = 1/0
        end)
      end

      -- true, "is ok"
      action.pcall3 = function()
        return pcall(function()
            return "is ok"
        end)
      end
    |
    MicroServer.Repo.query!(~s/update `scripts` set `content` = '#{lua_script}' where id = 1/)
    start_server()
    :ok
  end

  test "print 1" do
    MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "print1"}})
    Process.sleep(@waiting_print_finish)
    [_, _, print_content] = MicroServer.LogWork.read(@server_id) |> List.first()
    assert print_content =~ "this is print1 test!"
  end

  test "print 2" do
    MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "print2"}})
    Process.sleep(@waiting_print_finish)
    [_, _, print_content] = MicroServer.LogWork.read(@server_id) |> List.first()
    # print_content |> IO.inspect()
    assert print_content =~ "{\"a\":100.0,\"b\":200.0}"
  end

  test "pcall 1" do
    [response] =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "pcall1"}})

    assert response === 1001.0
  end

  test "pcall 2" do
    [response] =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "pcall2"}})

    assert response == false
  end

  test "pcall 3" do
    [state, result] =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "pcall3"}})

    assert state == true
    assert result == "is ok"
  end
end
