defmodule MicroServerTest.MyCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias MicroServer.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import MicroServerTest.MyCase

      @waiting_print_finish 500
      @server_id 1
      @waiting_server_start 1000
    end
  end

  setup_all tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(MicroServer.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(MicroServer.Repo, {:shared, self()})
    end

    MicroServer.Repo.query!(~s/DELETE FROM server_logs/)
    MicroServer.Repo.query!(~s/DELETE FROM users/)
    MicroServer.Repo.query!(~s/DELETE FROM access_partys/)
    MicroServer.Repo.query!(~s/DELETE FROM scripts/)
    MicroServer.Repo.query!(~s/DELETE FROM servers/)
    MicroServer.Repo.query!(~s/DELETE FROM server_scripts/)

    MicroServer.Repo.query!(
      ~s/INSERT INTO `users` (`id`, `username`, `email`, `mobile`, `password_hash`, `hidden`, `is_active`, `inserted_at`, `updated_at`) VALUES
    (1, 'max', 'honeymax@21cn.com', '18666680129', 'b20ec0fc084b8941f780bfdc90f94d54:3210', 0, 1, '2018-11-15 02:04:54', '2018-11-15 02:04:54')/
    )

    MicroServer.Repo.query!(
      ~s/INSERT INTO `access_partys` (`id`, `name`, `app_id`, `note`, `vip`, `type`, `is_active`, `users_id`, `inserted_at`, `updated_at`) VALUES
    (1, 'test', 'e16427c387923c1e48ee17ef4ad3e2ac', '测试用', 10001, 1, 1, 1, '2018-11-08 03:38:52', '2018-11-08 03:38:52')/
    )

    MicroServer.Repo.query!(
      ~s/INSERT INTO `scripts` (`id`, `name`, `note`, `content`, `type`, `access_partys_id`, `inserted_at`, `updated_at`) VALUES
    (1, 'test', '测试脚本', '', 1, 1, '2018-11-09 02:38:09', '2018-11-09 02:38:09')/
    )

    MicroServer.Repo.query!(
      ~s/INSERT INTO `servers` (`id`, `name`, `note`, `type`, `access_partys_id`, `inserted_at`, `updated_at`) VALUES
    (1, 'test', '测试服务器', 1, 1, '2018-11-08 08:42:24', '2018-11-09 02:49:59')/
    )

    MicroServer.Repo.query!(
      ~s/INSERT INTO `server_scripts` (`id`, `servers_id`, `scripts_id`, `inserted_at`, `updated_at`) VALUES
    (1, 1, 1, '2018-11-08 08:42:24', '2018-11-08 08:42:24')/
    )

    :ok
  end

  @server_id 1
  @waiting_server_start 1000
  def start_server() do
    MicroServer.ServerUtility.stop_server(@server_id)
    wait_server_stop()

    MicroServer.ServerUtility.start_server(@server_id)
    wait_server_start()
  end

  defp wait_server_stop() do
    case MicroServer.ServerUtility.get_server_pid(@server_id) do
      nil ->
        :ok

      _ ->
        wait_server_stop()
    end
  end

  defp wait_server_start() do
    case MicroServer.ServerUtility.get_server_pid(@server_id)  do
      nil ->
        wait_server_start()

      _ ->
        :ok
    end
  end
end
