defmodule MicroServer.LogUtility do
  @doc """
  code 日志记录
  """
  def log_code(server_id, code) do
    MicroServer.LogWork |> GenServer.cast({:code, server_id, code})
  end

  @doc """
  lua 日志记录
  """
  def log_lua(server_id, str) do
    MicroServer.LogWork |> GenServer.cast({:lua_print, server_id, str})
  end

  @doc """
  lua 输入错误日志记录
  """
  def log_call_lua_error(server_id, str) when is_binary(str) do
    MicroServer.LogWork |> GenServer.cast({:lua_error, server_id, str})
  end

  def log_call_lua_error(server_id, term) do
    MicroServer.LogWork
    |> GenServer.cast({:lua_error, server_id, term |> KunERAUQS.D0_f.json_encode()})
  end

  @doc """
  服务器收到链接进程退出日志
  """
  def server_exit_log(server_id, {%Mariaex.Error{}, _}) do
    log_call_lua_error(server_id, "mysql disconnect")
  end

  def server_exit_log(server_id, reason) do
    {:server_exit_log, reason} |> IO.inspect()
    log_call_lua_error(server_id, "unknow error")
  end
end
