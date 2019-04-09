defmodule MicroServer.ServerUtility do
  @moduledoc """
  该工具包装了对"微服务"操作的接口
  """
  alias Kunerauqs.EtsProxy
  alias MicroServer.CommonUtility

  require MicroServer.ServerLogConst
  MicroServer.ServerLogConst.create()

  @doc """
  [脏]启动"微服务"

  ## 参数

    - server_id: 服务器id(数据库 servers 表 id 字段的值)

  ## 返回

    - {:ok, pid} : 成功创建服务
    - {:error, term} : 创建服务失败

  ## 例子

      iex> MicroServer.ServerUtility.start_server(1)
      {:ok, #PID<0.244.0>}

  """
  @spec start_server(integer) :: {:ok, pid} | {:error, term}
  def start_server(server_id) do
    if server_exist?(server_id) == false do
      MicroServer.ServerSupervisor |> Supervisor.start_child([server_id])
    end

    # ==== :simple_one_for_one 使用 terminate_child 不会调用 worker的terminate方法
    # Supervisor.terminate_child(sup_pid, s_pid)
    # ====  使用 GenServer.stop 就会调用 worker的terminate方法
    # 会重启
    # GenServer.stop(s_pid, :other)
    # 以下3个都不会重启
    # GenServer.stop(s_pid) 等价于 GenServer.stop(s_pid, :normal)
    # GenServer.stop(s_pid)
    # GenServer.stop(s_pid, {:shutdown, :some_reason})
    # GenServer.stop(s_pid, :shutdown)
  end

  @doc """
  [脏]停止"微服务"

  ## 参数

    - server_id: 服务器id(数据库 servers 表 id 字段的值)

  ## 返回

    - :error: 服务器尚未启动
    - :ok: 成功关闭

  ## 例子

      iex> MicroServer.ServerUtility.stop_server(1)
      :ok

  """
  @spec stop_server(integer) :: :error | :ok
  def stop_server(server_id) do
    case get_server_pid(server_id) do
      nil -> :error
      server_pid -> GenServer.stop(server_pid, {:shutdown, @manual_shutdown})
    end
  end

  @doc """
  热更新
  """
  @spec hot_update_server(integer) :: :error | :ok | :hot_update_error
  def hot_update_server(server_id) do
    call(server_id, {:hot_update})
  end

  @doc """
  [脏]server是否存在, 用于判断server是否已经启动

  ## 参数

    - server_id: 服务器id(数据库 servers 表 id 字段的值)

  ## 例子

      iex> MicroServer.ServerUtility.server_exist?(-1)
      false

  """
  @spec server_exist?(integer) :: true | false
  def server_exist?(server_id) do
    # server work 的ram中是否存在 server_id 且 其对应的pid 活着
    if get_server_pid(server_id) == nil do
      false
    else
      true
    end
  end

  @doc """
  [脏]获取server pid

  ## 参数

    - server_id: 服务器id(数据库 servers 表 id 字段的值)

  ## 返回

    - nil: 服务器尚未启动
    - pid: 服务器对应的pid

  ## 例子

      iex> MicroServer.ServerUtility.get_server_pid(-1)
      nil

  """
  @spec get_server_pid(integer) :: nil | pid
  def get_server_pid(server_id) do
    case EtsProxy.read(MicroServer.ServerWork, server_id) do
      nil ->
        nil

      server_pid ->
        if CommonUtility.pid_alive?(server_pid) do
          server_pid
        else
          nil
        end
    end
  end

  @doc """
  [脏]向server发送信息, 并等待返回
  当 server_id 不存在时, 返回 :error

  ## 参数

    - server_id: 服务器id(数据库 servers 表 id 字段的值)
    - msg: 向进程传递的数据

  ## 返回

    - :error: 服务器尚未启动
    - term: 执行结果

  ## 例子

      iex> MicroServer.ServerUtility.call(-1, :hello)
      :error

  """
  @spec call(integer, term) :: :error | term
  def call(server_id, msg) do
    case get_server_pid(server_id) do
      nil ->
        :error

      server_pid ->
        try do
          server_pid |> GenServer.call(msg)
        rescue
          # 捕获一般性错误
          _ -> :time_out
        catch
          # 捕获 抛出错误(使用throw函数), exit, error 错误
          _ -> :time_out
          _, _ -> :time_out
        end
    end
  end

  @doc """
  [脏]向server发送信息, 异步

  ## 参数

    - server_id: 服务器id(数据库 servers 表 id 字段的值)
    - msg: 向进程传递的数据

  ## 返回

    - :error: 服务器尚未启动
    - :ok: 成功发送信息

  ## 例子

      iex> MicroServer.ServerUtility.cast(-1, :hello)
      :error

  """
  @spec cast(integer, term) :: :error | :ok
  def cast(server_id, msg) do
    case get_server_pid(server_id) do
      nil ->
        :error

      server_pid ->
        server_pid |> :gen_server.cast(msg)
        :ok
    end
  end

  @doc """
  判断 两个 server 是不是属于同一个access_party
  """
  def in_same_access_party?(server_id1, server_id2) do
    server1 = MicroServer.ServerController.get_server(server_id1)
    server2 = MicroServer.ServerController.get_server(server_id2)

    if server1 != nil && server2 != nil do
      server1.access_partys_id == server2.access_partys_id
    else
      false
    end
  end
end
