defmodule MicroServerTest.LuaLib.StringToolsTest do
  use MicroServerTest.MyCase, async: false

  setup_all do
    lua_script = ~s|
      require(string_tools)
      local action = {}

      function on_http(ticket, message)
        return action[message.c](message)
      end

      action.join1 = function()
        return string_tools.join(1,"hello",nil,true,{1,"hello",nil,true,name="Max"})
      end

      action.join2 = function()
        return string_tools.join({1,"hello",nil,true,{1,"hello",nil,true,name="Max"}})
      end

      action.join_with1 = function()
        return string_tools.join_with(" ", 1,"hello",nil,true,{1,"hello",nil,true,name="Max"})
      end

      action.join_with2 = function()
        return string_tools.join_with(" ", {1,"hello",nil,true,{1,"hello",nil,true,name="Max"}})
      end

      action.regex_match1 = function()
        return string_tools.regex_match("honeymax@21cn.com", "(?i-x)\b[\d!#$%&'*+./=?_`a-z{\|}~^-]+@[\d.a-z-]+\.[a-z]{2,6}\b")
      end

      action.regex_match2 = function()
        return string_tools.regex_match("honeymax21cn.com", "(?i-x)\b[\d!#$%&'*+./=?_`a-z{\|}~^-]+@[\d.a-z-]+\.[a-z]{2,6}\b")
      end

      action.json_encode = function()
        return string_tools.json_encode({name="Max", age=40}, "hello world", true, false, nil, {"hello world", true, false, "null", 1, 1.1})
      end

      action.json_decode = function()
        return
          string_tools.json_decode([[{"age":40,"name":"Max"}]]),
          string_tools.json_decode([[["hello world",true,false,null,1,1.1]]])
      end

      action.split = function()
        return
          string_tools.split("1,2,3,4,5,,6,7,8,9,,,10", ",")
      end

      action.simple_tpl1 = function()
        return
          string_tools.simple_tpl("{{1}} + {{2}} = {{3}}", {1, 4, 5})
      end

      action.simple_tpl2 = function()
        return
          string_tools.simple_tpl("My name is: {{first name}} {{last name}}", {["first name"]="Max", ["last name"]="Fang"})
      end

      action.simple_tpl3 = function()
        return
          string_tools.simple_tpl("My name is: {{first_name}} {{last_name}}", {first_name="Max", last_name="Fang"})
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

  test "join1" do
    [response] =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "join1"}})

    assert response =~ "1hellotrue{\"1\":1.0,\"2\":\"hello\",\"4\":true,\"name\":\"Max\"}"
  end

  test "join2" do
    [response] =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "join2"}})

    assert response =~ "1hellotrue{\"1\":1.0,\"2\":\"hello\",\"4\":true,\"name\":\"Max\"}"
  end

  test "join_with1" do
    [response] =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "join_with1"}})

    assert response =~ "1 hello  true {\"1\":1.0,\"2\":\"hello\",\"4\":true,\"name\":\"Max\"}"
  end

  # 注意结果的区别
  test "join_with2" do
    [response] =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "join_with2"}})

    assert response =~ "1 hello true {\"1\":1.0,\"2\":\"hello\",\"4\":true,\"name\":\"Max\"}"
  end

  test "regex_match1" do
    [response] =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "regex_match1"}})

    assert response == true
  end

  test "regex_match2" do
    [response] =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "regex_match2"}})

    assert response == false
  end

  test "json_encode" do
    response =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "json_encode"}})

    assert response == [
             "{\"age\":40,\"name\":\"Max\"}",
             "\"hello world\"",
             "true",
             "false",
             "\"nil\"",
             "[\"hello world\",true,false,null,1,1.1]"
           ]
  end

  test "json_decode" do
    response =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "json_decode"}})

    assert response == [
      %{"age" => 40, "name" => "Max"},
      ["hello world", true, false, :null, 1, 1.1]
    ]
  end

  test "split" do
    [response] =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "split"}})

    assert response == ["1", "2", "3", "4", "5", "", "6", "7", "8", "9", "", "", "10"]
  end

  test "simple_tpl1" do
    [response] =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "simple_tpl1"}})

    assert response == "1 + 4 = 5"
  end

  test "simple_tpl2" do
    [response] =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "simple_tpl2"}})

    assert response == "My name is: Max Fang"
  end

  test "simple_tpl3" do
    [response] =
      MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c" => "simple_tpl3"}})

    assert response == "My name is: Max Fang"
  end
end
