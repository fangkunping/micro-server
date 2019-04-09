defmodule MicroServer.Remoting.Server do
  alias MicroServer.ServerUtility
  alias MicroServer.Server
  alias MicroServer.Script
  alias MicroServer.ServerScript
  alias MicroServer.AccessPartyController
  alias MicroServer.Repo
  import Ecto.Query, only: [from: 2]
  require Ecto.Query
  # defdelegate start_server(server_id), to: ServerUtility
  # defdelegate stop_server(server_id), to: ServerUtility

  def start(server_id) do
    ServerUtility.start_server(server_id)
  end

  def stop(server_id) do
    ServerUtility.stop_server(server_id)
  end

  def hot_update(server_id) do
    ServerUtility.hot_update_server(server_id)
  end

  def send_message_to_lua(server_id, from_pid, type, msg) do
    ServerUtility.call(server_id, {from_pid, type, msg})
  end

  @doc """
  获取服务器列表
  """
  @spec get_servers(integer) :: list
  def get_servers(access_party_id) do
    AccessPartyController.get_servers(access_party_id)
    |> Enum.map(fn server ->
      is_runing? = ServerUtility.server_exist?(server.id)
      server |> Map.put(:is_runing?, is_runing?)
    end)
  end

  @doc """
  通过id获取Server内容
  """
  @spec get_server(integer, integer) :: map | nil
  def get_server(access_party_id, server_id) do
    server = Repo.get_by(Server, id: server_id, access_partys_id: access_party_id)

    server_scripts =
      from(
        s in ServerScript,
        where: s.servers_id == ^server_id,
        select: s
      )
      |> Repo.all()

    script_sequence =
      server_scripts
      |> Enum.map(fn server_script ->
        Repo.get_by(Script, id: server_script.scripts_id, access_partys_id: access_party_id)
      end)

    server |> Map.put(:script_sequence, script_sequence)
  end

  @doc """
  更新服务器
  """
  @spec update_server(integer, map) :: {:ok, any} | {:error, any}
  def update_server(access_party_id, server_params) do
    server =
      Repo.get_by(Server,
        id: server_params["id"] |> String.to_integer(),
        access_partys_id: access_party_id
      )

    changeset = Server.changeset(server, server_params)
    # 创建服务器与脚本的关联
    script_sequence = server_params["script_sequence"]
    create_server_script(access_party_id, script_sequence, server.id)
    Repo.update(changeset)
  end

  defp create_server_script(access_party_id, script_sequence, server_id) do
    from(p in ServerScript, where: p.servers_id == ^server_id) |> Repo.delete_all()

    script_ids =
      script_sequence
      |> String.split(",")
      |> Enum.map(fn script_id ->
        script_id |> String.to_integer()
      end)

    script_ids =
      from(
        s in Script,
        where: s.id in ^script_ids and s.access_partys_id == ^access_party_id,
        select: s.id
      )
      |> Repo.all()

    script_ids
    |> Enum.each(fn script_id ->
      changeset =
        ServerScript.changeset(%ServerScript{}, %{
          servers_id: server_id,
          scripts_id: script_id
        })

      Repo.insert(changeset)
    end)
  end

  @doc """
  创建服务器
  """
  @spec create_server(integer) :: :ok | {:error, String.t()}
  def create_server(access_party_id) do
    # 获取 access_party 的sever数量
    server_count =
      from(
        s in Server,
        where: s.access_partys_id == ^access_party_id,
        select: count(s.id)
      )
      |> Repo.one()

    # 数量超过限制
    server_create_max = Application.get_env(:micro_server, :server_create_max)

    if server_count < server_create_max do
      server_params = %{
        access_partys_id: access_party_id,
        name: "#{Kunerauqs.CommonTools.uuid()}",
        note: "#{Kunerauqs.CommonTools.uuid()}",
        script_sequence: "Enter the script id, separated by a comma",
        type: 1
      }

      changeset = Server.changeset(%Server{}, server_params)

      case Repo.insert(changeset) do
        {:ok, _} ->
          :ok

        {:error, _} ->
          {:error, "Database error"}
      end
    else
      {:error, "Reach maximum limit"}
    end
  end

  @doc """
  删除服务器
  """
  @spec delete_server(integer, integer) :: {:ok, any} | {:error, any}
  def delete_server(access_party_id, server_id) do
    server = Repo.get_by(Server, id: server_id, access_partys_id: access_party_id)
    Repo.delete(server)
  end

  @doc """
  启动服务器
  """
  @spec start_server(integer, integer) :: any
  def start_server(access_party_id, server_id) do
    server = Repo.get_by(Server, id: server_id, access_partys_id: access_party_id)
    start(server.id)
  end

  @doc """
  停止服务器
  """
  @spec stop_server(integer, integer) :: any
  def stop_server(access_party_id, server_id) do
    server = Repo.get_by(Server, id: server_id, access_partys_id: access_party_id)
    stop(server.id)
  end

  @doc """
  服务器 热更新
  """
  def hot_update_server(access_party_id, server_id) do
    server = Repo.get_by(Server, id: server_id, access_partys_id: access_party_id)
    hot_update(server.id)
  end

  @doc """
  服务器是否启动
  """
  @spec server_exist?(integer) :: boolean
  def server_exist?(server_id) do
    ServerUtility.server_exist?(server_id)
  end

  @doc """
  向服务器的lua端发送 websocket信息
  """
  @spec websocket_send_to_lua_websocket_message(integer, pid, term) :: :ok
  def websocket_send_to_lua_websocket_message(server_id, from_pid, message) do
    ServerUtility.call(server_id, {:lua_event, from_pid, :on_websocket, message})
  end

  @doc """
  向服务器的lua端发送http信息
  """
  @spec websocket_send_to_lua_http_message(atom, integer, term) :: :ok
  def websocket_send_to_lua_http_message(server_id, from_pid, message) do
    ServerUtility.call(server_id, {:lua_event, from_pid, :on_http, message})
  end

  @doc """
  向服务器的lua端发送topic链接信息
  """
  @spec websocket_send_to_lua_topic_join(integer, pid, term) :: :ok
  def websocket_send_to_lua_topic_join(server_id, from_pid, message) do
    ServerUtility.call(server_id, {:lua_event, from_pid, :on_websocket_open, message})
  end

  @doc """
  向服务器的lua端发送topic断开信息
  """
  @spec websocket_send_to_lua_topic_leave(integer, pid) :: :ok
  def websocket_send_to_lua_topic_leave(server_id, from_pid) do
    ServerUtility.call(server_id, {:lua_event, from_pid, :on_websocket_close, nil})
  end

  @doc """
  向服务器的lua端发送socket链接信息
  """
  @spec websocket_send_to_lua_socket_connect(integer, pid, term) :: :ok
  def websocket_send_to_lua_socket_connect(server_id, from_pid, message) do
    ServerUtility.call(server_id, {:lua_event, from_pid, :on_websocket_connect, message})
  end

  @doc """
  向服务器的lua端发送socket断开信息
  """
  @spec websocket_send_to_lua_socket_disconnect(integer, pid) :: :ok
  def websocket_send_to_lua_socket_disconnect(server_id, from_pid) do
    ServerUtility.call(server_id, {:lua_event, from_pid, :on_websocket_disconnect, nil})
  end

  @doc """
  获取服务器的log
  """
  @spec get_log(integer, integer) :: list
  def get_log(access_party_id, server_id) do
    server = Repo.get_by(Server, id: server_id, access_partys_id: access_party_id)
    MicroServer.LogWork.read(server.id)
  end
end
