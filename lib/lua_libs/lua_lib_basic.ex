defmodule MicroServer.LuaLib.Basic do
  alias MicroServer.LuaUtility
  alias MicroServer.LuaLibUtility
  alias MicroServer.CommonUtility
  alias MicroServer.ServerUtility
  alias MicroServer.AccessPartyController

  require Kunerauqs.GenRamFunction

  Kunerauqs.GenRamFunction.gen_def(
    write_concurrency: true,
    read_concurrency: true
  )

  def init_self do
    init_ram()
  end

  @doc """
  过程数据初始化函数, 在第一次获取过程数据的时候调用
  """
  @spec init_state :: map
  def init_state do
    %{}
  end

  @doc """
  模块需要用到的lua脚本
  """
  def addtion_lua do
    ~s|
      UPTIME = 0
      DELTA_TIME = 0

      function on_init()
      end
      function on_tick()
      end
      function on_hot_update()
      end
      function on_pipe_cast()
      end
      function on_pipe_call()
      end

      function apply(f, ...)
        return f(...)
      end

      __PCALL_F = nil
      function pcall(f, ...)
        __PCALL_F = f
        return pcall___run(...)
      end

      function pcall___run1(...)
        return __PCALL_F(...)
      end

      function create_iterator(t)
        local i = 0
        return function() i = i + 1;
          if type (t[i]) == "table" then
            return table.unpack(t[i])
          else
            return t[i]
          end
        end
      end

      string.gmatch = function(str, pattern)
        local t = {}
        local c = true
        while c do
          local f_t = {string.find(str, pattern)}
          local s, e
          s = f_t[1]
          e = f_t[2]
          if s == nil then
            c = false
          else
            if #f_t == 2 then
              table.insert(t, string.sub(str, s, e))
            else
              table.remove (f_t, 1)
              table.remove (f_t, 1)
              table.insert(t, f_t)
            end
            str = string.sub(str, e + 1)
          end
        end
        return create_iterator(t)
      end
    |
  end

  @doc """
  库初始化函数, 在启动微服务的时候调用
  """
  @spec init(lua_state :: term, String.t(), integer) :: new_lua_state :: term
  def init(lua_state, app_id, server_id) do
    pipe_tools__base_set(app_id)

    lua_state
    |> print(:print, server_id)
    |> print(:eprint, server_id)
    |> start_tick(server_id)
    |> stop_tick(server_id)
    |> server_info(app_id, server_id)
    |> trace()
    |> test()
    |> pcall()
    |> pipe_cast(app_id, server_id)
    |> pipe_call(app_id, server_id)
    |> lua_error()
  end
  @doc """
  返回当前服务器的信息

  ## lua 示例

      server_info()
  """
  def server_info(lua_state, app_id, server_id) do
    LuaUtility.set_value(lua_state, [:server_info], fn [], state ->
      {[server_id, app_id], state}
    end)
  end

  @doc """
  启动 on_tick

  ## lua 示例

      start_tick()
  """
  def start_tick(lua_state, server_id) do
    LuaUtility.set_value(lua_state, [:start_tick], fn [], state ->
      ServerUtility.cast(server_id, {:start_lua_tick})

      {[], state}
    end)
  end

  @doc """
  停止 on_tick

  ## lua 示例

      stop_tick()
  """
  def stop_tick(lua_state, server_id) do
    LuaUtility.set_value(lua_state, [:stop_tick], fn [], state ->
      ServerUtility.cast(server_id, {:stop_lua_tick})

      {[], state}
    end)
  end

  @doc """
  发送到其它服务器, 该服务器必须数属于同一个 access_party 用户

  ## lua 示例

      pipe_cast(1, "max", 20)
      pipe_cast(1, "hello world")
  """
  def pipe_cast(lua_state, app_id, server_id) do
    LuaUtility.set_value(lua_state, [:pipe_cast], fn [to_server_id | send_data], state ->
      to_server_id = to_server_id |> KunERAUQS.D0_f.number_to_int()

      if pipe_tools__in_app?(to_server_id, app_id) do
        ServerUtility.cast(
          to_server_id,
          {:on_pipe_cast, self(), [server_id | send_data]}
        )
      end

      {[], state}
    end)
  end

  @doc """
  发送到其它服务器, 并接收返回的值, 该服务器必须数属于同一个 access_party 用户

  ## lua 示例

      pipe_call(1, "max", 20)
      pipe_call(1, "hello world")
  """
  def pipe_call(lua_state, app_id, server_id) do
    LuaUtility.set_value(lua_state, [:pipe_call], fn [to_server_id | send_data], state ->
      to_server_id = to_server_id |> KunERAUQS.D0_f.number_to_int()

      if to_server_id == server_id do
        {result, new_state} =
          :luerl.call_function([:on_pipe_call], [-1, server_id | send_data], state)

        {[result], new_state}
      else
        if pipe_tools__in_app?(to_server_id, app_id) do
          result =
            ServerUtility.call(
              to_server_id,
              {:on_pipe_call, self(), [server_id | send_data]}
            )

          {[result], state}
        else
          {[], state}
        end
      end
    end)
  end

  @doc """
  输出到log

  ## lua 示例

      print(1, 2, 3)
      print({"name", "max"}, 20)
  """
  def print(lua_state, fun_name, server_id) do
    LuaUtility.set_value(lua_state, [fun_name], fn datas, state ->
      # datas
      # |> Enum.each(fn data ->
      str = KunERAUQS.D0_f.json_encode(datas)
      MicroServer.LogUtility.log_lua(server_id, str)
      # end)
      {[], state}
    end)
  end

  @doc """
  pcall(fn, ...) : false | true, any
  """
  def pcall(lua_state) do
    LuaUtility.set_value(lua_state, [:pcall___run], fn datas, state ->
      {result, new_state} =
        try do
          {result, new_state} = :luerl.call_function([:pcall___run1], datas, state)
          {[true | result], new_state}
        rescue
          # 捕获一般性错误
          e ->
            case e do
              %ErlangError{original: {:lib_error_throw, datas}} ->
                {[false | datas], state}

              _ ->
                {[false], state}
            end
        catch
          # 捕获 抛出错误(使用throw函数), exit, error 错误

          _ ->
            {[false], state}

          _, _ ->
            {[false], state}
        end

      {result, new_state}
    end)
  end

  @doc """
  error(any)
  """
  def lua_error(lua_state) do
    LuaUtility.set_value(lua_state, [:error], fn datas, state ->
      :erlang.error({:lib_error_throw, datas})

      {[], state}
    end)
  end

  def trace(lua_state) do
    if CommonUtility.is_dev_env?() do
      LuaUtility.set_value(lua_state, [:trace], fn datas, state ->
        {:lua_trace, datas} |> IO.inspect()
        {[], state}
      end)
    else
      LuaLibUtility.empty_function(lua_state, :trace)
    end
  end

  def test(lua_state) do
    LuaUtility.set_value(lua_state, [:test], fn datas, state ->
      datas |> IO.inspect()
      [f, params] = datas
      {res, state} = :luerl_emul.functioncall(f, [params], state) |> IO.inspect()
      {[res], state}
    end)
  end

  def pipe_tools__base_set(app_id) do
    access_party = AccessPartyController.get_access_party(app_id)

    server_ids =
      AccessPartyController.get_servers(access_party.id)
      |> Enum.map(fn server ->
        server.id
      end)

    write({:pipe_sessions, app_id}, server_ids)
  end

  def pipe_tools__in_app?(server_id, app_id) do
    server_id in read!({:pipe_sessions, app_id}, [])
  end
end
