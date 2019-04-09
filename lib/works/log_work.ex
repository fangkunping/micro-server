defmodule MicroServer.LogWork do
  @moduledoc """
  日志
  """
  use GenServer

  def start_link(arg, opts \\ []) do
    GenServer.start_link(__MODULE__, arg, [{:name, __MODULE__} | opts])
  end

  def init(_) do
    log_work_conf = Application.get_env(:micro_server, :log_work)

    conf =
      Kunerauqs.FileDB.init_self(%{
        store_path: log_work_conf.file_db_path,
        save_interval_time: log_work_conf.save_interval_time,
        addtion_store_encode: log_work_conf.addtion_store_encode,
        keep_cache_time: log_work_conf.keep_cache_time,
        use_cache?: log_work_conf.use_cache?,
        cache_table_name: :log_file_db_cache
      })

    {:ok, pid} = Kunerauqs.FileDB.start(conf)
    Map.put(conf, :pid, pid)
    MicroServer.RamUtility.write(:file_db_conf, conf)
    {:ok, nil}
  end

  def handle_cast({:code, server_id, code}, state) do
    add(server_id, [:code, MicroServer.CommonUtility.timestamp(), code])
    {:noreply, state}
  end

  def handle_cast({log_tag, server_id, str}, state) do
    add(
      server_id,
      [
        log_tag,
        MicroServer.CommonUtility.timestamp(),
        str |> String.slice(0..Application.get_env(:micro_server, :log_work).max_string_len)
      ]
    )

    {:noreply, state}
  end

  def handle_cast(_, state) do
    {:noreply, state}
  end

  defp add(server_id, value) do
    file_db_conf = MicroServer.RamUtility.read(:file_db_conf)
    old_value = read(server_id)
    new_value =
      if length(old_value) >= Application.get_env(:micro_server, :log_work).max_log_len do
        [value | old_value |> List.delete_at(-1)]
      else
        [value | old_value]
      end

    Kunerauqs.FileDB.write(file_db_conf, server_id, new_value)
  end

  def read(server_id) do
    file_db_conf = MicroServer.RamUtility.read(:file_db_conf)

    case Kunerauqs.FileDB.read(file_db_conf, server_id) do
      nil ->
        []

      v ->
        v
    end
  end
end
