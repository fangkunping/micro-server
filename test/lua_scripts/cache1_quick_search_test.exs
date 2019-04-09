defmodule MicroServerTest.LuaScript.Cache1QuickSearchTest do
  use MicroServerTest.MyCase, async: false

  test "test gen ms" do
    lua_script = ~s|
    cache1_table("man", id, name, age)
    cache1_table("class", id, math, english)
    cache1_table("animal", name, type, age)
    cache1_def_query("animal", "q_animal", [[name ~= '1' and age > '2']] )

    cache1.q_write("animal", {name=1, name=20, age=30})
    cache1.q_select("q_animal", "ludde", 30)
    |
    "=============================" |> IO.inspect()
    :ets.new(:test, [:set, :named_table])
    :ets.insert(:test, {:rufsen, :dog, 7})
    :ets.insert(:test, {:brunte, :horse, 5})
    :ets.insert(:test, {:ludde, :dog, 5})
    {:ok, parser} = MicroServer.LuaParserUtility.parse(lua_script) |> IO.inspect()
    cache1_table = MicroServer.LuaParserUtility.get_cache1_table(parser) |> IO.inspect()
    cache1_def_query = MicroServer.LuaParserUtility.get_cache1_def_query(parser) |> IO.inspect()
    # cache1_def_query |> Map.get("select1")
    ms =
      MicroServer.LuaLib.Cache1.gen_match_spec(cache1_table, cache1_def_query, "q_animal", [
        :ludde,
        6
      ])
      |> IO.inspect()

    :ets.select(:test, ms) |> IO.inspect()
  end

  test "test run server" do
    lua_script = ~s|
    require(cache1, web)
    cache1_table("animal", id, name, type, age)
    cache1_def_query("animal", "q_animal_1", [[name ~= "1" and age > "2"]] )
    cache1_def_query("animal", "q_animal_2", [[name ~= "1" and age > "2", name == "3"]] )

    function on_http(ticket, message)
      trace(cache1.q_write("animal", {id=10, name="tiger", age=3}))
      trace(cache1.q_write("animal", {id=11, name="cat", age=2}))
      trace(cache1.q_read("animal", 10))
      trace(cache1.q_select("q_animal_1", "dog", 1))
      local rs = cache1.q_select("q_animal_2", "dog", 4, "cat")
      for _,v in pairs(rs) do
        trace("result is: " .. v.name)
      end
      cache1.q_delete("q_animal_2", "dog", 4, "cat")
      trace(cache1.q_select("q_animal_1", "dog", 1))
    end

    |
    MicroServer.Repo.query!(~s/update `scripts` set `content` = '#{lua_script}' where id = 1/)
    start_server()
    MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{}}) |> IO.inspect()
    Process.sleep(@waiting_print_finish)
  end
end
