defmodule MicroServerTest.LuaScript.UnitTest do
  use MicroServerTest.MyCase, async: false

  setup_all do
    lua_script = ~s|
    require(string_tools)
    unit = {}

    unit.init = function()
        unit.results = {}
    end

    unit.assert = function(info, left, fn)
        local state, right = pcall(fn)
        local result = false
        if state then
            result = (left == right)
        else
            right = "script error!"
        end
        table.insert(unit.results, { info, state, result, left, right })
    end

    unit.report = function()
        local success = 0
        local fail = 0
        for i = 1, #unit.results do
            local info = unit.results[i][1]
            local state = unit.results[i][2]
            local result = unit.results[i][3]
            local left = unit.results[i][4]
            local right = unit.results[i][5]
            if state and result then
                success = success + 1
                print(string_tools.join_with(" ", "SUCCESS:[" , info , "]"))
            else
                fail = fail + 1
                print(string_tools.join_with(" ", "FAIL:[" , info , "] ", "left:[", left, "]", " right:[", right, "]"))
            end
        end
        print(string_tools.join_with(" ", "success: " , success))
        print(string_tools.join_with(" ", "fail: " , fail))
        print(string_tools.join_with(" ", "total test: " , #unit.results))
    end


    function on_http(ticket, message)
      unit.init()
      unit.assert("1 == 1", 1, function()
          return 1
      end)
      unit.assert("1 < 2", true, function()
          return 1 < 2
      end)
      unit.assert("1 / 0 < 2", true, function()
          return 1 / 0 < 2
      end)
      unit.report()
      return "ok"
    end

    |
    MicroServer.Repo.query!(~s/update `scripts` set `content` = '#{lua_script}' where id = 1/)
    start_server()
    :ok
  end

  test "unit" do
    MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{}}) |> IO.inspect()
    Process.sleep(@waiting_print_finish)
  end
end
