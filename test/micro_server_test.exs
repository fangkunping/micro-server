defmodule MicroServerTest do
  use ExUnit.Case
  doctest MicroServer



  test "greets the world" do
    assert MicroServer.hello() == :world
  end
end
