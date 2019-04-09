defmodule MicroServer.AppWork do
  use GenServer
  alias Kunerauqs.EtsProxy
  alias MicroServer.AccessPartyController
  alias MicroServer.ServerUtility
  alias MicroServer.AppWorkState, as: State

  require Kunerauqs.GenRamFunction

  Kunerauqs.GenRamFunction.gen_def(
    write_concurrency: true,
    read_concurrency: true
  )

  def init_self() do
    init_ram()
  end

  def start_link(arg, opts \\ []) do
    GenServer.start_link(__MODULE__, arg, opts)
  end

  def times_up(pid) do
    pid |> GenServer.cast({:times_up})
  end

  def init(access_party_id) do
    Process.flag(:trap_exit, true)

    access_party = AccessPartyController.get_access_party(access_party_id)

    app_id = access_party.app_id

    server_alive_check_time =
      Application.get_env(:micro_server, :app_work).server_alive_check_time

    setup_timer(server_alive_check_time)
    # 将信息写入 ram
    write(access_party_id, self())

    # 启动cache1 ets
    EtsProxy.init_ram(app_id |> String.to_atom())

    {:ok,
     %State{
       access_party_id: access_party_id,
       app_id: app_id,
       server_alive_check_time: server_alive_check_time
     }}
  end

  def handle_call(:ping, _, state) do
    {:reply, :pong, state}
  end

  def handle_cast(
        {:times_up},
        %State{
          access_party_id: access_party_id,
          server_alive_check_time: server_alive_check_time
        } = state
      ) do
    server_ids =
      AccessPartyController.get_servers(access_party_id)
      |> Enum.map(fn server ->
        server.id
      end)

    all_down? =
      server_ids
      |> Enum.all?(fn server_id ->
        ServerUtility.server_exist?(server_id) == false
      end)

    case all_down? do
      true ->
        {:stop, {:shutdown, :all_server_down}, state}

      false ->
        setup_timer(server_alive_check_time)
        {:noreply, state}
    end
  end

  def handle_info({:EXIT, _pid, _reason}, state) do
    {:noreply, state}
  end

  def handle_info(_, state) do
    # any_term |> IO.inspect()
    {:noreply, state}
  end

  def terminate(_, %State{access_party_id: access_party_id}) do
    delete(access_party_id)
  end

  def terminate(reason, state) do
    {reason, state} |> IO.inspect()
  end

  @doc """
  启动定时器
  """
  @spec setup_timer(integer) :: any
  def setup_timer(callback_time) do
    :timer.apply_after(callback_time, __MODULE__, :times_up, [self()])
  end
end
