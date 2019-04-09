defmodule MicroServer.ServerWorkConst do
  defmacro create do

    quote do
      def at_tick_time() do
        Application.get_env(:micro_server, :server_work).tick_time
      end
    end
  end
end
