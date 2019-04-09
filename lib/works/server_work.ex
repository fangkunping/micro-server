defmodule MicroServer.ServerWork do
  @moduledoc """
  微服务器工作进程. 该工作进程当前不存在超时停止的情况.
  """
  use GenServer
  alias MicroServer.LogUtility
  alias MicroServer.ServerController
  alias MicroServer.LuaUtility
  alias MicroServer.CommonUtility
  alias MicroServer.ServerWorkState, as: State
  alias MicroServer.LuaLibUtility
  alias MicroServer.ErrorUtility

  require MicroServer.ServerLogConst
  MicroServer.ServerLogConst.create()
  require MicroServer.ServerWorkConst
  MicroServer.ServerWorkConst.create()
  require MicroServer.StateConst
  MicroServer.StateConst.create()

  require Kunerauqs.GenRamFunction

  Kunerauqs.GenRamFunction.gen_def(
    write_concurrency: true,
    read_concurrency: true
  )

  @type server_work_state :: term
  @type from_ticket :: integer

  def init_self() do
    init_ram()
  end

  def start_link(arg, opts \\ []) do
    GenServer.start_link(__MODULE__, arg, opts)
  end

  def times_up(pid) do
    pid |> GenServer.cast({:times_up})
  end

  def init(server_id) do
    Process.flag(:trap_exit, true)
    {:ok, {:server_id, server_id}, 0}
  end

  def send_to_lua_event(
        %State{start_timestamp: start_timestamp, lua_state: lua_state, server_id: server_id} =
          state,
        from_pid,
        event_name,
        msg,
        is_msg_list? \\ false
      ) do
    uptime = CommonUtility.timestamp_ms() - start_timestamp

    {new_state, from_ticket} = create_tick_by_pid(state, from_pid)

    # {event_name, msg} |> IO.inspect()
    pass_params =
      if is_msg_list? do
        [from_ticket | msg]
      else
        [from_ticket, msg]
      end

    case LuaUtility.on_lua_event(lua_state, uptime, event_name, pass_params) do
      {:ok, ressults, new_lua_state} ->
        res =
          ressults
          |> Enum.map(fn res ->
            MicroServer.LuaLib.StringTools.pre_json_encode(res)
          end)

        # case event_name do
        #  :on_http -> MicroServer.LuaLib.StringTools.pre_json_encode(res)
        #  _ -> res
        # end

        {:reply, res, %State{new_state | lua_state: new_lua_state}}

      {:error, reason} ->
        ErrorUtility.error_log(server_id, event_name, msg, reason)

        {:reply, :call_lua_error, state}
        # {:stop, {:shutdown, @lua_script_run_error}, :ok, state}
    end
  end

  @doc """
  http|websocket 信息入
  """
  def handle_call({:lua_event, event, msg}, {from_pid, _tag}, state) do
    send_to_lua_event(state, from_pid, event, msg)
  end

  def handle_call({:lua_event, from_pid, event, msg}, _from, state) do
    send_to_lua_event(state, from_pid, event, msg)
  end

  def handle_call({:on_pipe_call, from_pid, msg}, _from, state) do
    send_to_lua_event(state, from_pid, :on_pipe_call, msg, true)
  end

  @doc """
  热更新
  """
  def handle_call(
        {:hot_update},
        _from,
        %State{
          lua_state: lua_state,
          server_id: server_id,
          addtion_libs: old_addtion_libs,
          app_id: app_id
        } = state
      ) do
    # 读取脚本
    scripts = ServerController.get_script(server_id)
    # 读取附加库
    case LuaUtility.hot_update_state(lua_state, scripts, old_addtion_libs) do
      {:ok, lua_state, addtion_libs} ->
        LogUtility.log_code(server_id, @hot_update)

        # 加入lua函数库 过程数据
        lua_state =
          LuaLibUtility.add_addtion_libs_state(app_id, server_id, lua_state, addtion_libs)

        # 预编译 cache1 快速搜索 table和query 并添加入 过程数据
        MicroServer.LuaLib.Cache1.add_process_state(scripts, server_id)

        # 调用初始化函数, 执行脚本初始化
        case LuaUtility.call(lua_state, [:on_hot_update], []) do
          # 初始化函数错误
          {:error, reason} ->
            ErrorUtility.error_log(server_id, "on server hot update", [], reason)

            {:reply, :hot_update_error, state}

          {_res, lua_state} ->
            {:reply, :ok,
             %State{
               state
               | lua_state: :luerl.gc(lua_state),
                 next_gc_timestamp: CommonUtility.timestamp_ms(),
                 addtion_libs: addtion_libs |> Enum.concat(old_addtion_libs)
             }}
        end

      {:error, reason} ->
        ErrorUtility.error_log(server_id, "on server hot update", [], reason)

        {:reply, :hot_update_error, state}
    end
  end

  @doc """
  收到其它服务器, 传来的数据, 发送到 自身
  """
  def handle_cast({:on_pipe_cast, from_pid, msg}, state) do
    {_, _, state} = send_to_lua_event(state, from_pid, :on_pipe_cast, msg, true)

    {:noreply, state}
  end

  @doc """
  定时时间到
  """
  def handle_cast(
        {:times_up},
        %State{
          server_id: server_id,
          start_timestamp: start_timestamp,
          last_tick_timestamp: last_tick_timestamp,
          next_gc_timestamp: next_gc_timestamp,
          lua_state: lua_state,
          is_call_on_tick?: is_call_on_tick?
        } = state
      ) do
    # 启动tick 定时
    setup_timer(at_tick_time())
    now_timestamp = CommonUtility.timestamp_ms()

    # gc
    {next_gc_timestamp, lua_state} =
      if now_timestamp > next_gc_timestamp do
        {now_timestamp + apply(MicroServer.Runtime.Config, :lua, []).gc_interval,
         :luerl.gc(lua_state)}
      else
        {next_gc_timestamp, lua_state}
      end

    # 调用 lua 脚本的 on_tick函数
    if is_call_on_tick? do
      delta_time = now_timestamp - last_tick_timestamp
      uptime = now_timestamp - start_timestamp

      case LuaUtility.tick(lua_state, uptime, delta_time) do
        {:ok, new_lua_state} ->
          # 激活传输队列
          self() |> GenServer.cast({:start_send})

          {:noreply,
           %State{
             state
             | last_tick_timestamp: now_timestamp,
               next_gc_timestamp: next_gc_timestamp,
               lua_state: new_lua_state
           }}

        {:error, reason} ->
          ErrorUtility.error_log(server_id, "on_tick", [], reason)

          # {:noreply,
          # %State{
          #   state
          #   | last_tick_timestamp: now_timestamp,
          #     next_gc_timestamp: next_gc_timestamp
          # }}

          {:stop, {:shutdown, @lua_script_run_error}, state}
      end
    else
      # 激活传输队列
      self() |> GenServer.cast({:start_send})

      {:noreply,
       %State{
         state
         | last_tick_timestamp: now_timestamp,
           next_gc_timestamp: next_gc_timestamp,
           lua_state: lua_state
       }}
    end
  end

  @doc """
  启动 lua 脚本的 on_tick 调用
  """
  def handle_cast({:start_lua_tick}, %State{} = state) do
    {:noreply, %State{state | is_call_on_tick?: true}}
  end

  @doc """
  停止 lua 脚本的 on_tick 调用
  """
  def handle_cast({:stop_lua_tick}, %State{} = state) do
    {:noreply, %State{state | is_call_on_tick?: false}}
  end

  @doc """
  将lua传出的数据加入将要传送到来源的队列.
  """
  def handle_cast(
        {:start_send},
        %State{
          send_queues: send_queues
        } = state
      ) do
    send_queues
    |> Map.to_list()
    |> Enum.each(fn {tick, send_messages} ->
      case fetch_pid_ticket_pair(state, tick) do
        nil -> nil
        from_pid -> send(from_pid, {:response, send_messages})
      end
    end)

    {:noreply, %State{state | send_queues: %{}}}
  end

  @doc """
  将lua数据传输出去
  """
  def handle_cast(
        {:add_send_queue, ticks, send_message},
        %State{
          send_queues: send_queues
        } = state
      ) do
    # send_message = LuaUtility.table_to_map(lua_table)

    ticks =
      if is_number(ticks) do
        [{1, ticks}]
      else
        ticks
      end

    send_queues =
      ticks
      |> Enum.reduce(send_queues, fn {_index, tick}, send_queues ->
        tick = tick |> :erlang.round()
        tick_message_queues = send_queues |> Map.get(tick, [])
        send_queues |> Map.put(tick, [send_message | tick_message_queues])
      end)

    {:noreply, %State{state | send_queues: send_queues}}
  end

  @doc """
  tick_pid断开
  """
  def handle_info({:DOWN, _ref, :process, tick_pid, _reason}, state) do
    new_state = delete_pid_ticket_pair(state, tick_pid)
    {:noreply, new_state}
  end

  @doc """
  [脏]使用立即超时(timeout = 0), 进行真正初始化
  """
  def handle_info(:timeout, {:server_id, server_id}) do
    state = %State{server_id: server_id}

    f = fn
      {_, lstate}, "判断 server_id 是否存在" ->
        case ServerController.server_exist?(server_id) do
          false ->
            {@fail,
             %{
               lstate
               | result: {:stop, {:shutdown, @no_server_id_exist_in_database}, state}
             }}

          true ->
            {@continue, lstate}
        end

      {@continue, lstate}, "读取app_id和access_party_id" ->
        access_party = ServerController.get_access_party(server_id)
        {@continue, %{lstate | app_id: access_party.app_id, access_party_id: access_party.id}}

      {@continue, lstate}, "读取script信息" ->
        {@continue, %{lstate | scripts: ServerController.get_script(server_id)}}

      {@continue, %{scripts: scripts, app_id: app_id, access_party_id: access_party_id} = lstate},
      "将script 编译后写入 state" ->
        # 附加的lua脚本

        case LuaUtility.init_state(scripts) do
          {:ok, lua_state, addtion_libs} ->
            LogUtility.log_code(server_id, @start_up)

            now_timestamp = CommonUtility.timestamp_ms()
            # 启动tick 定时
            setup_timer(at_tick_time())
            # 加入lua函数库 过程数据
            lua_state =
              LuaLibUtility.add_addtion_libs_state(app_id, server_id, lua_state, addtion_libs)

            # 初始化 lua函数库 过程数据
            LuaLibUtility.init_state(server_id)

            # 预编译 cache1 快速搜索 table和query 并添加入 过程数据
            MicroServer.LuaLib.Cache1.add_process_state(scripts, server_id)

            # 启动 app server
            MicroServer.AppUtility.start_app(access_party_id)

            # 将信息写入 ram
            write(server_id, self())

            # 调用初始化函数, 执行脚本初始化
            case LuaUtility.call(lua_state, [:on_init], []) do
              # 初始化函数错误
              {:error, reason} ->
                ErrorUtility.error_log(server_id, "on server start", [], reason)

                {@fail,
                 %{
                   lstate
                   | result: {:stop, {:shutdown, @lua_script_load_error}, state}
                 }}

              {_res, lua_state} ->
                {@finish,
                 %{
                   lstate
                   | result:
                       {:noreply,
                        %State{
                          state
                          | lua_state: :luerl.gc(lua_state),
                            start_timestamp: now_timestamp,
                            last_tick_timestamp: now_timestamp,
                            next_gc_timestamp: now_timestamp,
                            addtion_libs: addtion_libs,
                            app_id: app_id,
                            access_party_id: access_party_id
                        }}
                 }}
            end

          {:error, reason} ->
            ErrorUtility.error_log(server_id, "on server start", [], reason)

            {@fail,
             %{
               lstate
               | result: {:stop, {:shutdown, @lua_script_load_error}, state}
             }}
        end

      {_, %{result: result}}, :return ->
        result

      lstate_full, _ ->
        lstate_full
    end

    {@continue,
     %{
       scripts: "",
       app_id: "",
       access_party_id: nil,
       result: nil
     }}
    |> f.("判断 server_id 是否存在")
    |> f.("读取app_id和access_party_id")
    |> f.("读取script信息")
    |> f.("将script 编译后写入 state")
    |> f.(:return)
  end

  def handle_info({:EXIT, _pid, reason}, %State{server_id: server_id} = state) do
    LogUtility.server_exit_log(server_id, reason)
    {:noreply, state}
  end

  def handle_info(any_term, state) do
    {:server_work, :unknow_message, any_term} |> IO.inspect()
    {:noreply, state}
  end

  def terminate_common(server_id, state) do
    delete(server_id)
    LuaLibUtility.destroy_state(server_id)
    notify_shell_server_down(state)
  end

  @doc """
  [脏]已知原因关闭
  """
  def terminate({:shutdown, reson_code}, %State{server_id: server_id} = state)
      when is_integer(reson_code) do
    LogUtility.log_code(server_id, reson_code)
    terminate_common(server_id, state)
  end

  @doc """
  [脏]正常关闭
  """
  def terminate(:normal, %State{server_id: server_id} = state) do
    LogUtility.log_code(server_id, @normal_shutdown)
    terminate_common(server_id, state)
  end

  @doc """
  [脏]其它未知错误关闭, 自动重启
  """

  def terminate(reason, %State{server_id: server_id} = state) do
    LogUtility.log_code(server_id, @unknow_shutdown)
    terminate_common(server_id, state)
    {reason, state} |> IO.inspect()
  end

  def terminate(reason, {:server_id, server_id}) do
    reason |> IO.inspect()
    LogUtility.log_code(server_id, @unknow_shutdown)
    delete(server_id)
    LuaLibUtility.destroy_state(server_id)
  end

  @doc """
  启动定时器
  """
  @spec setup_timer(integer) :: any
  def setup_timer(callback_time) do
    :timer.apply_after(callback_time, __MODULE__, :times_up, [self()])
  end

  @doc """
  从来源的pid 生成/获得 tick
  """
  @spec create_tick_by_pid(server_work_state, pid) :: {server_work_state, from_ticket}
  def create_tick_by_pid(state, from_pid) do
    f = fn
      {_, lstate}, "from_pid 是否已经存在?" ->
        {@continue, %{lstate | is_from_pid_exist?: from_pid_exist?(state, from_pid)}}

      {@continue, %{is_from_pid_exist?: true} = lstate}, "读取from_pid,对应的ticket" ->
        {@finish,
         %{lstate | new_state: state, from_ticket: fetch_pid_ticket_pair(state, from_pid)}}

      {@continue, %{is_from_pid_exist?: false} = lstate}, "生成新的ticket" ->
        {new_state, from_ticket} = create_from_ticket(state)
        {@continue, %{lstate | new_state: new_state, from_ticket: from_ticket}}

      {@continue, %{from_ticket: from_ticket, new_state: new_state} = lstate},
      "保存新的pid ticket键值对" ->
        Process.monitor(from_pid)

        {@finish,
         %{
           lstate
           | new_state: store_pid_ticket_pair(new_state, from_pid, from_ticket),
             from_ticket: from_ticket
         }}

      {_, lresult}, :return ->
        lresult

      lstate_full, _ ->
        lstate_full
    end

    lresult =
      {@continue,
       %{
         is_from_pid_exist?: nil,
         new_state: nil,
         from_ticket: nil
       }}
      |> f.("from_pid 是否已经存在?")
      |> f.("读取from_pid,对应的ticket")
      |> f.("生成新的ticket")
      |> f.("保存新的pid ticket键值对")
      |> f.(:return)

    {lresult.new_state, lresult.from_ticket}
  end

  @doc """
  pid已经记录?
  """
  @spec from_pid_exist?(server_work_state, pid) :: true | false
  def from_pid_exist?(%State{pid_ticket_pair: pid_ticket_pair}, from_pid) do
    Map.has_key?(pid_ticket_pair, from_pid)
  end

  @spec from_ticket_exist?(server_work_state, integer) :: true | false
  def from_ticket_exist?(%State{pid_ticket_pair: pid_ticket_pair}, integer) do
    Map.has_key?(pid_ticket_pair, integer)
  end

  @doc """
  生成新的from_ticket
  """
  @spec create_from_ticket(server_work_state) :: {server_work_state, from_ticket}
  def create_from_ticket(%State{from_ticket: from_ticket} = state) do
    new_from_ticket = from_ticket + 1
    {%State{state | from_ticket: new_from_ticket}, new_from_ticket}
  end

  @doc """
  记录pid和tick键值对
  """
  @spec store_pid_ticket_pair(server_work_state, pid, from_ticket) :: server_work_state
  def store_pid_ticket_pair(%State{pid_ticket_pair: pid_ticket_pair} = state, pid, ticket) do
    %State{
      state
      | pid_ticket_pair:
          pid_ticket_pair
          |> Map.put(pid, ticket)
          |> Map.put(ticket, pid)
    }
  end

  @doc """
  取出pid和tick键值对
  """
  @spec fetch_pid_ticket_pair(server_work_state, pid | integer) :: integer | pid | nil
  def fetch_pid_ticket_pair(%State{pid_ticket_pair: pid_ticket_pair}, key) do
    Map.get(pid_ticket_pair, key)
  end

  @doc """
  删除pid和tick键值对
  """
  @spec delete_pid_ticket_pair(server_work_state, pid | integer) :: server_work_state
  def delete_pid_ticket_pair(%State{pid_ticket_pair: pid_ticket_pair} = state, key) do
    if Map.has_key?(pid_ticket_pair, key) do
      value = Map.get(pid_ticket_pair, key)

      %State{
        state
        | pid_ticket_pair:
            pid_ticket_pair
            |> Map.delete(key)
            |> Map.delete(value)
      }
    else
      state
    end
  end

  @doc """
  通知shell 服务已经关闭
  """
  def notify_shell_server_down(%State{server_id: server_id, app_id: app_id}) do
    MicroServer.Notify.Server.server_down(app_id, server_id)
  end
end
