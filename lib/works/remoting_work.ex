defmodule MicroServer.RemotingWork do
  @moduledoc """
  分布链接定时监测
  没有连上, 每秒进行连接检测
  连上后, 按照间隔 1, 2, 4, 8, ... max_callback_time
  """
  use GenServer

  require MicroServer.RemotingWorkConst
  MicroServer.RemotingWorkConst.create()

  def start_link(arg, opts \\ []) do
    GenServer.start_link(__MODULE__, arg, opts)
  end

  def times_up(pid) do
    pid |> GenServer.call({:times_up})
  end

  # ======================================================
  # = GenServer implementation
  # ======================================================
  def init(_) do
    setup_timer(at_min_callback_time())

    {:ok,
     %{
       callback_time: at_min_callback_time(),
       shell_node: Application.get_env(:micro_server, :remoting_work).shell_node
     }}
  end

  # 定时时间到
  def handle_call(
        {:times_up},
        _form,
        %{callback_time: callback_time, shell_node: shell_node} = state
      ) do
    # "times up" |> IO.inspect()
    new_callback_time =
      case :net_adm.ping(shell_node) do
        :pang -> at_min_callback_time()
        :pong -> callback_time * 2
      end

    setup_timer(new_callback_time)

    {:reply, :ok,
     %{
       state
       | callback_time:
           (new_callback_time > at_max_callback_time() && at_max_callback_time()) ||
             new_callback_time
     }}
  end

  # ======================================================
  # = local
  # ======================================================
  def setup_timer(callback_time) do
    :timer.apply_after(callback_time, __MODULE__, :times_up, [self()])
  end
end
