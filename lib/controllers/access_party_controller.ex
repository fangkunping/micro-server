defmodule MicroServer.AccessPartyController do
  alias MicroServer.Server
  alias MicroServer.Repo
  alias MicroServer.AccessParty
  import Ecto.Query, only: [from: 2]
  require Ecto.Query

  @doc """
  [脏]获取access_party数据
  """
  @spec get_access_party(integer) :: map | nil
  def get_access_party(access_party_id) when is_integer(access_party_id) do
    case Repo.get(AccessParty, access_party_id) do
      nil ->
        nil

      access_party ->
        access_party
    end
  end

  def get_access_party(app_id) do
    case Repo.get_by(AccessParty, app_id: app_id) do
      nil ->
        nil

      access_party ->
        access_party
    end
  end

  def get_servers(access_party_id) do
    from(
      s in Server,
      where: s.access_partys_id == ^access_party_id,
      select: s
    )
    |> Repo.all()
  end
end
