defmodule MicroServer.RuntimeExsUtility do
  def init_self() do
    runtime_exs_conf = Application.get_env(:micro_server, :runtime_exs)
    path = runtime_exs_conf.path

    runtime_exs_conf.files
    |> Enum.each(fn file_basename ->
      "#{path}#{file_basename}.exs"
      |> Code.compile_file()
    end)
  end
end
