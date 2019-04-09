defmodule MicroServer.ServerWorkState do
  defstruct(
    # 服务器对应的id
    server_id: nil,
    # lua状态机
    lua_state: nil,
    # 服务器启动时的时间戳 (毫秒)
    start_timestamp: nil,
    # 上次运行tick的时间 (毫秒)
    last_tick_timestamp: nil,
    # 下次运行gc的时间 (毫秒)
    next_gc_timestamp: nil,
    # http 或 socket 访问时, 相同来源的pid都会生成一个唯一的from_tick
    from_ticket: 0,
    # 来源 pid 和 tick 键值对, 双向键值对, 同时记录了 pid -> tick 和 tick -> pid
    pid_ticket_pair: %{},
    # 传输到来源的队列, 这里储存的是键值对, tick :: integer -> message :: list
    send_queues: %{},
    # lua 用户程序里面附加的函数库
    addtion_libs: [],
    # 是否开启 on_tick 调用
    is_call_on_tick?: false,
    # app_id
    app_id: "",
    access_party_id: nil
  )
end
