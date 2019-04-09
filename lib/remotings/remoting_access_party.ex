defmodule MicroServer.Remoting.AccessParty do
  alias MicroServer.Repo
  alias MicroServer.AccessParty
  # import Ecto.Query, only: [from: 2]
  # require Ecto.Query

  @doc """
  通过appid 获取AccessParty
  """
  @spec get_access_party(String.t()) :: access_party :: map | nil
  def get_access_party(app_id) do
    Repo.get_by(AccessParty, app_id: app_id)
  end
end
