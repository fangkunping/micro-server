defmodule MicroServer.ServerLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "server_logs" do
    belongs_to(:servers, MicroServer.Server)
    field(:log, :string)
    field(:erl_log, :string)

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:servers_id, :log, :erl_log])
    |> validate_required([:servers_id])
    |> foreign_key_constraint(:servers_id, name: :server_logs_servers_id_fkey)
  end
end
