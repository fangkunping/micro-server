#c("J:/NEW_WORLD/20xx/projects/micro_server/test/runtime_test/pressure_test.exs")
#MicroServerTest.PressureTest.start()
defmodule MicroServerTest.PressureTest do
  def start() do
    for i <- 1..2000 do
      spawn(fn -> loop() end)
    end
  end

  def loop() do
    receive do
      _ ->
        loop()
    after
      1000 ->
        MicroServer.ServerUtility.call(9, {:lua_event, :on_test_run, %{}})
        loop()
    end
  end
end
