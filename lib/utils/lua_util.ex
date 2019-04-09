defmodule MicroServer.LuaUtility do
  @moduledoc """
  该工具包装了对Lua操作的接口

  ### lua 缺省内部函数

  每一个lua状态机都必须包含以下函数

    - init()
    - tick()

  ### lua 缺省外部接口

    - message_fetch()

  """
  alias MicroServer.LuaParserUtility
  alias MicroServer.LuaLibUtility
  require MicroServer.LuaConst
  MicroServer.LuaConst.create()

  @type res :: list
  @type lua_state :: term
  @type reason :: term
  @type lua_table :: term
  @type millisecond :: integer
  @type lua_value :: term
  @type from_ticket :: integer

  @doc """
  初始化lua状态机
  """
  @spec init_state(scripts :: list) :: {:ok, lua_state, addtion_libs :: list} | {:error, reason}
  def init_state(scripts) do
    case create_addtion_libs(scripts) do
      {:error, reason_str} ->
        {:error, reason_str}

      {:ok, addtion_libs} ->
        scripts_all =
          scripts
          |> Enum.map(fn script ->
            script.content
          end)
          |> Enum.join("\n")

        compile_lua(nil, addtion_libs, scripts_all)
    end
  end

  @doc """
  热更新lua状态机
  """
  def hot_update_state(lua_state, scripts, old_addtion_libs) do
    case create_addtion_libs(scripts) do
      {:error, reason_str} ->
        {:error, reason_str}

      {:ok, addtion_libs} ->
        addtion_libs =
          addtion_libs
          |> Enum.filter(fn lib ->
            lib not in old_addtion_libs
          end)

        scripts_all =
          scripts
          |> Enum.map(fn script ->
            script.content
          end)
          |> Enum.join("\n")

        compile_lua(lua_state, addtion_libs, scripts_all)
    end
  end

  @doc """
  获取程序需要的函数库
  """
  @spec create_addtion_libs(scripts :: list) :: {:ok, addtion_libs :: list} | {:error, reason}
  def create_addtion_libs(scripts) do
    parser_result =
      scripts
      |> Enum.reduce_while([], fn script, addtion_libs ->
        case LuaParserUtility.parse(script.content) do
          {:ok, parser} ->
            {:cont, LuaParserUtility.get_require_modules(parser) |> Enum.concat(addtion_libs)}

          {:parse_error, error_line} ->
            {:halt,
             {:error, "something wrong on line #{error_line} [#{script.name}][#{script.note}]!"}}

          {:scan_error, error_line} ->
            {:halt,
             {:error, "something wrong on line #{error_line} [#{script.name}][#{script.note}]!"}}
        end
      end)

    # 词法语法分析 程序, 获得程序需要的函数库
    case parser_result do
      {:error, reason_str} ->
        {:error, reason_str}

      _ ->
        addtion_libs = parser_result |> Enum.uniq()
        {:ok, addtion_libs}
    end
  end

  @doc """
  编译 lua
  """
  @spec compile_lua(old_lua_state :: any, addtion_libs :: list, String.t()) ::
          {:ok, lua_state, addtion_libs :: list} | {:error, reason}
  def compile_lua(old_lua_state, addtion_libs, scripts_all) do
    case run(old_lua_state, LuaLibUtility.addtion_lua(@default_function, addtion_libs)) do
      # 读取缺省脚本错误
      {:error, reason} ->
        {:error, reason}

      {_res, lua_default_state} ->
        case run(lua_default_state, scripts_all) do
          # 载入用户脚本错误
          {:error, reason} ->
            {:error, reason}

          {_res, lua_state} ->
            {:ok, lua_state, addtion_libs}
        end
    end
  end

  @doc """
  tick 时间到
  """
  @spec tick(lua_state, millisecond, millisecond) :: {:ok, lua_state} | :error
  def tick(state, uptime, delta_time) do
    new_state =
      state
      |> set_value([:UPTIME], uptime)
      |> set_value([:DELTA_TIME], delta_time)

    case call(new_state, [:on_tick], []) do
      {:error, reason} ->
        {:error, reason}

      {_res, lua_state} ->
        {:ok, lua_state}
    end
  end

  @doc """
  http 信息入
  """
  @spec on_lua_event(lua_state, millisecond, atom, list) :: {:ok, lua_state} | :error
  def on_lua_event(state, uptime, event_name, params) do
    new_state =
      state
      |> set_value([:UPTIME], uptime)

    case call(new_state, [event_name], params) do
      {:error, reason} ->
        {:error, reason}

      {res, lua_state} ->
        {:ok, res, lua_state}
    end
  end

  #
  @doc """
  执行lua程序

  ## 例子

      iex> {res, state} = MicroServer.LuaUtility.run("return {1,2,3,4,5};")
      iex> res
      [tref: 13]
      iex> :luerl.decode_list(res, state)
      [[{1, 1.0}, {2, 2.0}, {3, 3.0}, {4, 4.0}, {5, 5.0}]]

  """
  @spec run(String.t()) :: {res, lua_state} | {:error, reason}
  def run(scripts) do
    try do
      :luerl.do(scripts)
    rescue
      e ->
        {:error, e}
    end
  end

  def run(nil, scripts) do
    run(scripts)
  end

  @spec run(lua_state, String.t()) :: {res, lua_state} | {:error, reason}
  def run(state, scripts) do
    try do
      :luerl.do(scripts, state)
    rescue
      e ->
        {:error, e}
    end
  end

  @doc """
  调用lua函数

  ## 例子

      iex> {res, state} = MicroServer.LuaUtility.run("function my_print(a) print(a); return a; end")
      iex> {res, state} = MicroServer.LuaUtility.call(state, [:my_print], ["hello world!"])
      iex> res
      ["hello world!"]

  """
  @spec call(lua_state, list, list) :: {res, lua_state} | {:error, reason}
  def call(state, path, params) do
    try do
      :luerl.call_function(path, params, state)
    rescue
      e ->
        {:error, e}
    end
  end

  @doc """
  将map转化成可以在lua内表现的table

  ## 例子

      iex> MicroServer.LuaUtility.map_to_table(%{"age" => 10, "name" => "max"})
      [{"age", 10}, {"name", "max"}]
      iex> MicroServer.LuaUtility.map_to_table(%{age: 10, name: :max})
      [{"age", 10}, {"name", "max"}]

  """
  @spec map_to_table(map) :: lua_table
  def map_to_table(m) when is_map(m) do
    m
    |> Map.to_list()
    |> Enum.map(fn {k, v} ->
      {map_to_table(k), map_to_table(v)}
    end)
  end

  def map_to_table(v) when is_atom(v) do
    Atom.to_string(v)
  end

  def map_to_table(any) do
    any
  end

  @doc """
  将lua内表现的table转化成map

  ## 例子

      iex> {res, state} = MicroServer.LuaUtility.table_to_map([{"age", 10}, {"name", "max"}])
      %{"age" => 10, "name" => "max"}

  """
  @spec table_to_map(lua_table) :: map
  def table_to_map(l) when is_list(l) do
    l
    |> Enum.reduce(%{}, fn
      {k, v}, m when is_number(k) ->
        m |> Map.put(MicroServer.LuaLib.StringTools.format_number(k) |> KunERAUQS.D0_f.number_to_string(), table_to_map(v))

      {k, v}, m ->
        m |> Map.put(k, table_to_map(v))
    end)
  end

  def table_to_map(v) when is_number(v) do
    MicroServer.LuaLib.StringTools.format_number(v)
  end
  def table_to_map(any) do
    any
  end

  @doc """
  设置lua里面变量的值

  ## 例子

      # 设置函数
      state =
        MicroServer.LuaUtility.set_value(
          [:send_to],
          fn [player_id, data], state ->
            NetDelayTemplateLua.Game.send_to(player_id, data)
            {[nil], state}
          end,
          state
        )

      # 设置变量
      iex> {_res, state} = MicroServer.LuaUtility.run("a = 1")
      iex> state = MicroServer.LuaUtility.set_value(state,[:b],10)
      iex> MicroServer.LuaUtility.run(state, "return a + b") |> elem(0)
  """
  @spec set_value(lua_state, list, lua_value) :: lua_state
  def set_value(state, path, value) when is_function(value) do
    f = fn params, state ->
      try do
        value.(params, state)
      rescue
        # 捕获一般性错误
        e ->
          case e do
            %ErlangError{original: {:lib_error_throw, _}} ->
              :erlang.error(e)

            _ ->
              throw_lua_inline_error(state, path, params)
          end
      catch
        # 捕获 抛出错误(使用throw函数), exit, error 错误
        # {:lib_lua_error, error_str} -> throw_lua_inline_error(state, error_str)
        _ ->
          throw_lua_inline_error(state, path, params)

        _, _ ->
          throw_lua_inline_error(state, path, params)
      end
    end

    :luerl.set_table(path, f, state)
  end

  def set_value(state, path, value) do
    :luerl.set_table(path, value, state)
  end

  def throw_lua_inline_error(state, path, params) do
    path_str = path |> Enum.map(&(&1 |> Atom.to_string())) |> Enum.join(".")
    params_str = params |> KunERAUQS.D0_f.json_encode()

    :luerl_lib.lua_error(
      {:inline_function_error, "call '#{path_str}(#{params_str})' error!"},
      state
    )
  end

  def throw_lua_inline_error(state, error_str) do
    :luerl_lib.lua_error({:inline_function_error, error_str}, state)
  end

  def throw_lib_lua_error(error_str) do
    :erlang.error({:lib_lua_error, error_str})
  end
end
