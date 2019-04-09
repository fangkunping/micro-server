defmodule MicroServer.AccessParty do
  use Ecto.Schema
  import Ecto.Changeset

  schema "access_partys" do
    field(:name, :string)
    field(:app_id, :string)
    field(:note, :string)
    field(:vip, :integer)
    field(:type, :integer)
    field(:is_active, :boolean, default: true)
    belongs_to(:users, MicroServer.User)

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :app_id, :note, :vip, :is_active, :users_id])
  end
end
