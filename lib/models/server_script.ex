defmodule MicroServer.ServerScript do
  use Ecto.Schema
  import Ecto.Changeset

  schema "server_scripts" do
    belongs_to(:servers, MicroServer.Server)
    belongs_to(:scripts, MicroServer.Script)

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:servers_id, :scripts_id])
    |> validate_required([:servers_id, :scripts_id])
    |> foreign_key_constraint(:servers_id, name: :server_scripts_servers_id_fkey)
    |> foreign_key_constraint(:scripts_id, name: :server_scripts_scripts_id_fkey)
  end
end
