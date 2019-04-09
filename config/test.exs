use Mix.Config

config :micro_server,
  log_work: %{
    file_db_path: "z:/tmp/micro_server/",
    # 定时保存时间 10_000
    save_interval_time: 1_000,
    # cache 保存时间 20_000
    keep_cache_time: 2_000,
    use_cache?: false,
    # log 队列长度
    max_log_len: 50,
    # log 字符串输出长度
    max_string_len: 256,
    # 附加存储格式
    addtion_store_encode: [:json]
  }


# Configure your database
config :micro_server, MicroServer.Repo,
  adapter: Ecto.Adapters.MySQL,
  username: "root",
  password: "maxfkp",
  database: "micro_server",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
