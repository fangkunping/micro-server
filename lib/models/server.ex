defmodule MicroServer.Server do
  use Ecto.Schema
  import Ecto.Changeset

  schema "servers" do
    field(:name, :string)
    field(:note, :string)
    field(:type, :integer)
    field(:script_sequence, :string, virtual: true)
    belongs_to(:access_partys, MicroServer.AccessParty)

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :note, :access_partys_id, :script_sequence])
    |> validate_required([:name, :note, :script_sequence])
    |> foreign_key_constraint(:access_partys_id, name: :servers_access_partys_id_fkey)
  end


end
