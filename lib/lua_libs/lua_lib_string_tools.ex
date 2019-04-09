defmodule MicroServer.LuaLib.StringTools do
  alias MicroServer.LuaUtility

  @doc """
  过程数据初始化函数, 在第一次获取过程数据的时候调用
  """
  @spec init_state :: map
  def init_state, do: %{}

  @doc """
  模块需要用到的lua脚本
  """
  def addtion_lua() do
    ""
  end

  @doc """
  库初始化函数, 在启动微服务的时候调用
  """
  @spec init(lua_state :: term, String.t(), integer) :: new_lua_state :: term
  def init(lua_state, _app_id, _server_id) do
    lua_state
    |> LuaUtility.set_value([:string_tools], [])
    |> lua_string_join()
    |> lua_string_join_with()
    |> lua_string_regex_match()
    |> lua_string_json_encode()
    |> lua_string_json_decode()
    |> lua_string_split()
    |> lua_string_simple_tpl()
  end

  @doc """
  string_tools.join(...)
  """
  def lua_string_join(lua_state) do
    LuaUtility.set_value(lua_state, [:string_tools, :join], fn datas, state ->
      result =
        case datas do
          [data_list] when is_list(data_list) ->
            data_list
            |> Enum.map(fn
              {_, v} ->
                format_string_join_input(v)
            end)
            |> Enum.join()

          _ ->
            datas
            |> Enum.map(fn v ->
              format_string_join_input(v)
            end)
            |> Enum.join()
        end

      {[result], state}
    end)
  end

  @doc """
  string_tools.join_with(",", ...)
  """
  def lua_string_join_with(lua_state) do
    LuaUtility.set_value(lua_state, [:string_tools, :join_with], fn [sp | datas], state ->
      result =
        case datas do
          [data_list] when is_list(data_list) ->
            data_list
            |> Enum.map(fn
              {_, v} ->
                format_string_join_input(v)
            end)
            |> Enum.join("#{sp}")

          _ ->
            datas
            |> Enum.map(fn v ->
              format_string_join_input(v)
            end)
            |> Enum.join("#{sp}")
        end

      {[result], state}
    end)
  end

  @doc """
  string_tools.regex_match("honeymax@21cn.com", "(?i-x)\b[\d!#$%&'*+./=?_`a-z{|}~^-]+@[\d.a-z-]+\.[a-z]{2,6}\b")
  Regex.match?(~r/foo/, "foo")
  """
  def lua_string_regex_match(lua_state) do
    LuaUtility.set_value(lua_state, [:string_tools, :regex_match], fn [or_str, re_str], state ->
      result =
        case restr_replace(re_str) |> Regex.compile() do
          {:ok, regex} ->
            Regex.match?(regex, or_str)

          {:error, _} ->
            nil
        end

      {[result], state}
    end)
  end

  @doc """
  ## 注意
    - 字符串 "null" 会被替换成 null
    - {2,3,4} 会成为json数组
    - 3.0 类型的数值会被替换成整数 3

  string_tools.json_encode(...)
  """
  def lua_string_json_encode(lua_state) do
    LuaUtility.set_value(lua_state, [:string_tools, :json_encode], fn datas, state ->
      results =
        datas
        |> Enum.map(fn data ->
          json_encode(data)
        end)

      {results, state}
    end)
  end

  @doc """
  ##注意
    - null 会被替换成 字符串 "null"
    - 整数都会被替换成 小数
  string_tools.json_decode("")
  """
  def lua_string_json_decode(lua_state) do
    LuaUtility.set_value(lua_state, [:string_tools, :json_decode], fn [str], state ->
      result =
        str
        |> KunERAUQS.D0_f.json_decode()
        |> LuaUtility.map_to_table()

      {[result], state}
    end)
  end

  @doc """
  切分字符串

      string_tools.split(str, str_sp) -> table
  """
  def lua_string_split(lua_state) do
    LuaUtility.set_value(lua_state, [:string_tools, :split], fn [str, str_sp], state ->
      result =
        str
        |> String.split(str_sp)
        |> LuaUtility.map_to_table()

      {[result], state}
    end)
  end

  @doc """
  建议模板

      string_tools.simple_tpl(string, table) -> string
  """
  def lua_string_simple_tpl(lua_state) do
    LuaUtility.set_value(lua_state, [:string_tools, :simple_tpl], fn [tpl, table], state ->

      result = Kunerauqs.SimpleTemplate.render(tpl, LuaUtility.table_to_map(table))

      {[result], state}
    end)
  end

  # 替换特殊字符
  defp restr_replace(re_str) do
    [
      {"\b", "\\b"},
      {"\B", "\\B"},
      {"\c", "\\c"},
      {"\d", "\\d"},
      {"\D", "\\D"},
      {"\f", "\\f"},
      {"\n", "\\n"},
      {"\r", "\\r"},
      {"\s", "\\s"},
      {"\S", "\\S"},
      {"\t", "\\t"},
      {"\v", "\\v"},
      {"\w", "\\w"},
      {"\W", "\\W"},
      {"\n", "\\n"},
      {"\p", "\\p"},
      {"\<", "\\<"},
      {"\>", "\\>"}
    ]
    |> Enum.reduce(re_str, fn {pattern, replacement}, re_str ->
      re_str |> String.replace(pattern, replacement)
    end)
  end

  defp format_string_join_input(v) when is_list(v) do
    KunERAUQS.D0_f.json_encode(v)
  end

  defp format_string_join_input(v) when is_number(v) do
    if KunERAUQS.D0_f.number_to_int(v) == v do
      "#{KunERAUQS.D0_f.number_to_int(v)}"
    else
      "#{v}"
    end
  end

  defp format_string_join_input(v) do
    "#{v}"
  end

  def json_encode(data) do
    pre_json_encode(data) |> KunERAUQS.D0_f.json_encode()
  end

  def pre_json_encode(l) when is_list(l) do
    case l do
      [] ->
        []

      [{k, _} | _] when is_number(k) ->
        l
        |> Enum.map(fn {_, v} ->
          pre_json_encode(v)
        end)

      _ ->
        l
        |> Enum.map(fn {k, v} ->
          {pre_json_encode(k), pre_json_encode(v)}
        end)
        |> :maps.from_list()
    end
  end

  def pre_json_encode(v) when is_number(v) do
    format_number(v)
  end

  def pre_json_encode("null") do
    :null
  end

  def pre_json_encode(v) do
    v
  end

  def format_number(v) when is_number(v) do
    if KunERAUQS.D0_f.number_to_int(v) == v do
      KunERAUQS.D0_f.number_to_int(v)
    else
      v
    end
  end

  def format_number(v) do
    v
  end
end
