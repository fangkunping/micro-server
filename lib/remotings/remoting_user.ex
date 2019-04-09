defmodule MicroServer.Remoting.User do
  alias MicroServer.Repo
  alias MicroServer.User
  alias MicroServer.AccessParty

  @doc """
  通过用户id 获取用户数据
  """
  def get_user(userid) do
    add_access_party_to_user(Repo.get(User, userid))
  end

  @doc """
  通过 用户名, 密码, 获取用户数据
  """
  @spec get_user(String.t(), String.t()) :: user :: map | nil
  def get_user(username, password) do
    case Repo.get_by(User, username: username) do
      nil ->
        nil

      user ->
        case Kunerauqs.ZenCartPassword.zen_validate_password(password, user.password_hash) do
          true -> add_access_party_to_user(user)
          false -> nil
        end
    end
  end

  defp add_access_party_to_user(nil) do
    nil
  end

  defp add_access_party_to_user(user) do
    access_party = Repo.get_by(AccessParty, users_id: user.id)

    user
    |> Map.put(
      :access_party,
      access_party |> Map.put(:vip_type, "vip#{access_party.vip}" |> String.to_atom())
    )
  end
end
