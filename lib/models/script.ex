defmodule MicroServer.Script do
  use Ecto.Schema
  import Ecto.Changeset

  schema "scripts" do
    field(:name, :string)
    field(:note, :string)
    field(:content, :string)
    field(:type, :integer)
    belongs_to(:access_partys, MicroServer.AccessParty)

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :note, :content, :type, :access_partys_id])
    #|> validate_required([:name, :note, :content])
    |> foreign_key_constraint(:access_partys_id, name: :scripts_access_partys_id_fkey)
  end
end
