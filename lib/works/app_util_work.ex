defmodule MicroServer.AppUtilityWork do
  alias MicroServer.AppUtility
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:start_app, access_party_id}, _, state) do
    app_pid =
      case AppUtility.get_app_pid(access_party_id) do
        nil ->
          MicroServer.AppSupervisor |> Supervisor.start_child([access_party_id])

        pid ->
          pid
      end

    res =
      try do
        case app_pid |> GenServer.call(:ping) do
          :pong -> {:ok, app_pid}
          _ -> {:error, nil}
        end
      rescue
        # 捕获一般性错误
        _ -> {:error, nil}
      catch
        # 捕获 抛出错误(使用throw函数), exit, error 错误
        _ -> {:error, nil}
        _, _ -> {:error, nil}
      end

    {:reply, res, state}
  end
end
