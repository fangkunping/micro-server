# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :micro_server, ecto_repos: [MicroServer.Repo]

config :micro_server,
  app_work: %{
    # 10 分钟检查一次, 10*60*1000
    server_alive_check_time: 600_000
    # server_alive_check_time: 5000
  },
  server_work: %{
    # 毫秒,lua脚本on_tick间隔时间
    tick_time: 200
  },
  remoting_work: %{
    # shell 节点名称
    shell_node: :"shell@127.0.0.1",
    # 毫秒, 定义分布定时链接检查时的最小和最大间隔时间
    callback_time: %{
      min: 1000,
      max: 10000
    }
  },
  # lua 日志相关配置
  log_work: %{
    file_db_path: "z:/tmp/micro_server/",
    # 定时保存时间 10_000
    save_interval_time: 1_000,
    # cache 保存时间 20_000
    keep_cache_time: 2_000,
    use_cache?: true,
    # log 队列长度
    max_log_len: 50,
    # log 字符串输出长度
    max_string_len: 2048,
    # 附加存储格式
    addtion_store_encode: [:json]
  },
  # 运行时动态加载 脚本
  runtime_exs: %{
    # 脚本所在地址
    path: "J:/NEW_WORLD/20xx/projects/micro_server/runtime_exs/",
    # 脚本名称, 不需要后缀
    files: ["config"]
  },
  tmp_folder: "d:/tmp/",
  # 每个 access_party 可创建的服务器数量
  server_create_max: 10,
  # 每个 access_party 可创建的脚本数量
  script_create_max: 50

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :micro_server, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:micro_server, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

import_config "#{Mix.env()}.exs"
