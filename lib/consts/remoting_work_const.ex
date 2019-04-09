defmodule MicroServer.RemotingWorkConst do
  defmacro create do
    quote do
      def at_min_callback_time() do
        Application.get_env(:micro_server, :remoting_work).callback_time.min
      end
      def at_max_callback_time() do
        Application.get_env(:micro_server, :remoting_work).callback_time.max
      end
    end
  end
end
