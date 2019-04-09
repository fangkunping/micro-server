defmodule MicroServer.Runtime.Config do
  @doc """
  在编辑状态 使用 MicroServer.Runtime.Config.lua() 获取数据会产生编译错误
  因为此时 MicroServer.Runtime.Config 还未编译和加载到内存
  所以使用以下方式调用
  apply(MicroServer.Runtime.Config, :lua, []).lib_conf[__MODULE__].http_request_interval
  """
  def lua() do
    %{
      # 30 分钟 进行一次GC操作 30 * 60 * 1000
      # gc_interval: 1_800_000,
      gc_interval: 60_000,
      extend_libs: [
        # 缺省必须载入的函数库
        # 其它函数库使用前 需要使用 require 函数载入
        MicroServer.LuaLib.Basic,
        MicroServer.LuaLib.Table
      ],
      lib_conf: %{
        MicroServer.LuaLib.Web => %{
          # 申请http的间隔时间
          http_request_interval: 0
        },
        MicroServer.LuaLib.Cache1 => %{
          # 1级缓存大小 单位 b , 16kb = 1024 * 16b
          # level1_cache_size: 16384
          # 1级缓存大小 b, 16mb = 1024 * 1024 * 16b
          level1_cache_size: 16_777_216
        },
        MicroServer.LuaLib.Cache2 => %{
          # 2级缓存大小 b, 16mb = 1024 * 1024 * 16b
          level2_cache_size: 16_777_216,
          level2_cache_path: "z:/tmp/micro_server/"
        }
      }
    }
  end

  def poolboy() do
    [
      [
        {:name, {:local, :lua_lib_http_worker}},
        {:worker_module, MicroServer.LuaLibWebWork},
        {:size, 1}
      ]
    ]
  end
end
