defmodule MicroServer.Notify.Server do
  alias MicroServer.Notify

  @doc """
  通知shell 服务器关闭
  """
  @spec server_down(integer, integer) :: any
  def server_down(app_id, server_id) do
    Notify.call(MicroServerShell.Notify.Server, :server_down, [app_id, server_id])
  end
end
