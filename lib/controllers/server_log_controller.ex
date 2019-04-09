defmodule MicroServer.ServerLogController do
  alias MicroServer.ServerLog
  alias MicroServer.Repo

  @doc """
  [脏]写入 code 作为记录
  """
  @spec write_code(integer, integer) :: any()
  def write_code(server_id, code) do
    changeset =
      ServerLog.changeset(%ServerLog{}, %{
        servers_id: server_id,
        log: code |> Integer.to_string()
      })

    Repo.insert(changeset)
  end
end
