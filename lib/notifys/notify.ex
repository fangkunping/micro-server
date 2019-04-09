defmodule MicroServer.Notify do
  @doc """
  通过appid 获取AccessParty
  """
  @spec call(atom, atom, list) :: any
  def call(module, fun, args) do
    node = Application.get_env(:micro_server, :remoting_work).shell_node

    case :rpc.call(node, module, fun, args) do
      {:badrpc, reason} ->
        reason |> IO.inspect()
        raise "rpc run error"

      res ->
        res
    end
  end
end
