defmodule MicroServer.StateConst do
  defmacro create do
    quote do
      @continue 1
      @fail 2
      @finish 3
    end
  end
end
