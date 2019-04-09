defmodule MicroServerTest.LuaLib.MySqlTest do
  use MicroServerTest.MyCase, async: false

  setup_all do
    lua_script = ~s|
      require(mysql)
      local action = {}

      function on_http(ticket, message)
        return action[message.c](message)
      end

      action.mysql_connect = function()
        trace(mysql.connect({username="root", password="maxfkp", database="test",hostname="localhost",port=3306}))
        return "ok"
      end

      action.insert = function()
        mysql.connect({username="root", password="maxfkp", database="test",hostname="localhost",port=3306})
        mysql.query("INSERT INTO test_tb set name = ?", "Max")
        mysql.query("INSERT INTO test_tb set name = ?", "Max")
        mysql.query("INSERT INTO test_tb set name = ?", "Max")
        return mysql.query("INSERT INTO test_tb set name = ?", "Max")
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

  test "mysql_connect" do
    [response] =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "mysql_connect"}})

    assert response == "ok"
  end

  test "mysql_insert" do
    [response] =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "insert"}})

    assert response == "ok"
  end
end
