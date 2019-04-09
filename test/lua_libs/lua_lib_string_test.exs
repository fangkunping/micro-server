defmodule MicroServerTest.LuaLib.StringTest do
  use MicroServerTest.MyCase, async: false

  setup_all do
    lua_script = ~s|
      require(string_tools)
      local action = {}

      function on_http(ticket, message)
        return action[message.c](message)
      end

      action.find = function()
        return
          {string.find('Hanazawa Kana', 'na')},
          {string.find('Hanazawa Kana', '[%a]+')},
          {string.find('2015-5-12 13:53', '(%d+)-(%d+)-(%d+)')},
          {string.find('2015-5-12 13:53', '(%d+)-(%d+)-(%d+)', 1, true)},
          {string.find('%a1234567890%a', '%a', 3, true)}
      end

      action.match = function()
        return
          {string.match('2015-5-12 13:53', '%d+-%d+-%d+')},
          {string.match('2015-5-12 13:53', '(%d+)-(%d+)-(%d+)')},
          {string.match('2015-5-12 13:53', '((%d+)-(%d+)-(%d+))')}
      end

      action.gmatch = function()
      local f1 = function()
        local r = ""
          for s in string.gmatch('2015-5-12 22:20', '%d+') do
            r=string_tools.join_with(",",r,s)
          end
        return r
      end
      local f2 = function()
        local r = ""
          for s in string.gmatch('Hanazawa Kana', 'a(%a)a') do
            r=string_tools.join_with(",",r,s)
          end
        return r
      end
      local f3 = function()
        local r = ""
          for k, v in string.gmatch('a=214,b=233', '(%w+)=(%w+)') do
            r=string_tools.join_with(",",r,k,v)
          end
        return r
      end
      return f1(), f2(), f3()
      end

    |
    # MicroServer.Repo.query!(~s/update `scripts` set `content` = '#{lua_script}' where id = 1/)
    script = Repo.get!(MicroServer.Script, 1)

    changeset =
      MicroServer.Script.changeset(script, %{
        content: lua_script
      })

    Repo.update(changeset) |> IO.inspect()

    start_server()
    :ok
  end

  test "find" do
    response =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "find"}})
      |> IO.inspect()

    assert response == [
             [{1, 3.0}, {2, 4.0}],
             [{1, 1.0}, {2, 8.0}],
             [{1, 1.0}, {2, 9.0}, {3, "2015"}, {4, "5"}, {5, "12"}],
             [],
             [{1, 13.0}, {2, 14.0}]
           ]
  end

  test "match" do
    response =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "match"}})
      |> IO.inspect()

    assert response == [
             [{1, "2015-5-12"}],
             [{1, "2015"}, {2, "5"}, {3, "12"}],
             [{1, "2015-5-12"}, {2, "2015"}, {3, "5"}, {4, "12"}]
           ]
  end

  test "gmatch" do
    response =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "gmatch"}})
      |> IO.inspect()

    assert response == [",2015,5,12,22,20", ",n,w,n", ",a,214,b,233"]
  end
end
