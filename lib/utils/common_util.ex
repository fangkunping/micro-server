defmodule MicroServer.CommonUtility do
  require MicroServer.LuaConst
  MicroServer.LuaConst.create()

  @type utc_millisecond :: integer
  @type utc_second :: integer

  @spec pid_alive?(any) :: true | false
  def pid_alive?(pid) do
    if pid != nil && Process.alive?(pid) do
      true
    else
      false
    end
  end

  @spec timestamp_ms() :: utc_millisecond
  def timestamp_ms() do
    DateTime.utc_now() |> DateTime.to_unix(:millisecond)
  end

  @spec timestamp() :: utc_second
  def timestamp() do
    DateTime.utc_now() |> DateTime.to_unix()
  end

  @doc """
  调用使用pool的功能
  """
  @spec pool_call(atom, any) :: any | system_limit :: String.t()
  def pool_call(pool_name, params) do
    case :poolboy.checkout(pool_name, false) do
      :full ->
       @lib_system_limit
      pid ->
        try do
          {"try to call", pid} |> IO.inspect()
          result = GenServer.call(pid, params)
          :poolboy.checkin(pool_name, pid)
          result
        rescue
          # 捕获一般性错误
          _ ->
            :poolboy.checkin(pool_name, pid)
            @lib_system_limit
        catch
          # 捕获 抛出错误(使用throw函数), exit, error 错误
          _ ->
            :poolboy.checkin(pool_name, pid)
            @lib_system_limit

          _, _ ->
            :poolboy.checkin(pool_name, pid)
            @lib_system_limit
        end
    end
  end

  @doc """
  判断当前环境
  """
  def is_dev_env?() do
    System.get_env("MIX_ENV") != "prod"
  end

  def is_prod_env?() do
    System.get_env("MIX_ENV") == "prod"
  end
end
