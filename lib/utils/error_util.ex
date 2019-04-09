defmodule MicroServer.ErrorUtility do
  alias MicroServer.LogUtility
  # def format(%ErlangError{original: {:lua_error, {:error_call, reason}, _}}) do
  #  reason
  # end
  # def format(%ErlangError{original: {:lua_error, {:illegal_index,tab,key}, _}}) do
  #  nil
  # end
  # 用于程序执行时 elixir 手动 抛出错误
  def format(%ErlangError{original: {:lib_lua_error, error_str}}) do
    error_str
  end

  # 用于 lua error 函数 抛出错误
  def format(%ErlangError{original: {:lib_error_throw, error_datas}}) do
    "error throw: #{KunERAUQS.D0_f.json_encode(error_datas)}"
  end

  def format(%ErlangError{original: {:lua_error, {:inline_function_error, reason}, _}}) do
    "inline function error: " <> reason
  end

  def format(%ErlangError{original: {:lua_error, reason, _}}) do
    reason |> :erlang.tuple_to_list() |> KunERAUQS.D0_f.json_encode()
  end

  def format(%MatchError{term: {:error, [{line, :luerl_parse, reason}], []}}) do
    "parse: line[#{line}] #{reason}"
  end

  def format(reason) when is_binary(reason) do
    reason
  end

  def format(%{message: reason}) do
    reason
  end

  def format(reason) do
    {"format", reason} |> IO.inspect()
    nil
  end

  def error_log(server_id, event_name, params, reason) do
    reason = format(reason)

    LogUtility.log_call_lua_error(server_id, %{
      event: event_name,
      params: params,
      reason: reason
    })
  end
end
