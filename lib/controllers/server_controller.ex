defmodule MicroServer.ServerController do
  alias MicroServer.Repo
  alias MicroServer.Server
  alias MicroServer.Script
  alias MicroServer.ServerScript
  import Ecto.Query

  require MicroServer.LuaConst
  MicroServer.LuaConst.create()

  @doc """
  [脏]获取微服务器的脚本
  """
  @spec get_script(integer) :: String.t()
  def get_script(server_id) do
    from(
      p in ServerScript,
      where: p.servers_id == ^server_id,
      select: p
    )
    |> Repo.all()
    |> Enum.map(fn server_script ->
      # 读取脚本详细信息
      Repo.get(Script, server_script.scripts_id)
    end)
  end

  @doc """
  [脏]微服务器是否存在
  """
  @spec server_exist?(integer) :: true | false
  def server_exist?(server_id) do
    case Repo.get(Server, server_id) do
      nil ->
        false

      _server ->
        true
    end
  end

  @doc """
  [脏]获取服务器所在的access_party数据
  """
  @spec get_access_party(integer) :: map | nil
  def get_access_party(server_id) do
    case Repo.get(Server, server_id) do
      nil ->
        nil

      server ->
        MicroServer.AccessPartyController.get_access_party(server.access_partys_id)
    end
  end

  @doc """
  [脏]获取服务器信息
  """
  @spec get_server(integer) :: map | nil
  def get_server(server_id) do
    case Repo.get(Server, server_id) do
      nil ->
        nil

      server ->
        server
    end
  end
end
