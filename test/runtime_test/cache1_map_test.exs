# c("J:/NEW_WORLD/20xx/projects/micro_server/test/runtime_test/cache1_map_test.exs")
# MicroServerTest.Cache1MapTest.start()
defmodule MicroServerTest.Cache1MapTest do
  def start() do
    {"cache1 test: ", cache1_test()} |> IO.inspect()
    {"map test: ", map_test()} |> IO.inspect()
  end

  def cache1_test() do
    t1 = Kunerauqs.CommonTools.timestamp_ms()

    for _ <- 1..200000 do
      MicroServer.ServerUtility.call(5, {:lua_event, :on_http, %{}})
    end

    t2 = Kunerauqs.CommonTools.timestamp_ms()
    t2 - t1
  end

  def map_test() do
    t1 = Kunerauqs.CommonTools.timestamp_ms()

    for _ <- 1..200000 do
      MicroServer.ServerUtility.call(4, {:lua_event, :on_http, %{}})
    end

    t2 = Kunerauqs.CommonTools.timestamp_ms()
    t2 - t1
  end
end
