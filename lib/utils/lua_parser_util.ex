defmodule MicroServer.LuaParserUtility do
  def parse(scripts) when is_binary(scripts) do
    scripts |> String.to_charlist() |> parse()
  end

  @spec parse(String.t()) :: {:ok, any} | {:error, String.t()}
  def parse(scripts) do
    case scripts |> :luerl_scan.string() do
      {:ok, tokens, _} ->
        case tokens |> :luerl_parse.parse() do
          {:ok, v} ->
            {:ok, v}

          {:error, {error_line, :luerl_parse, _}} ->
            {:parse_error, error_line}
        end

      {:error, {error_line, _, _}, _} ->
        # e |> IO.inspect()
        # {202, :luerl_scan, {:illegal, [65374]}}
        # {:error, "something wrong on line #{error_line}!"}
        {:scan_error, error_line}
    end
  end

  # ============== 以下代码 暂时屏蔽 =============
  # @doc """
  # 将lua的字符串提取出来,并进行词法分析, 例如
  #  将 "[[name ~= 1 and age > 2]]"
  #  提取出 "name ~= 1 and age > 2"
  #  并进行 parse("name ~= 1 and age > 2")
  # """
  # def parse_inline_string(scripts) when is_binary(scripts) do
  #  scripts |> String.to_charlist() |> parse()
  # end
  #
  # def parse_inline_string(scripts) do
  #  case scripts |> :luerl_scan.string() do
  #    {:ok, [{:STRING, _, s}], _} ->
  #      parse(s)
  #
  #    _ ->
  #      {:scan_error, 1}
  #  end
  # end
  # ============== 以上代码 暂时屏蔽 =============
  @doc """
  require的模块名称 解析
  """
  def get_require_modules(parser) do
    # {:., _line, {:NAME, _, :require},
    # {:functioncall, 1,
    # [{:NAME, 1, :apple}, {:NAME, 1, :dde}, {:STRING, 1, "ll"}]}}

    parser
    |> Enum.filter(fn
      {:., _line, {:NAME, _, :require}, {:functioncall, _, _}} -> true
      _ -> false
    end)
    |> Enum.reduce([], fn {:., _line, {:NAME, _, :require}, {:functioncall, _, modules}}, acc ->
      modules
      |> Enum.reduce(acc, fn {_, _, module}, acc ->
        module =
          "#{module}" |> String.split("_") |> Enum.map(&String.capitalize(&1)) |> Enum.join()

        ["Elixir.MicroServer.LuaLib.#{module}" |> String.to_atom() | acc]
      end)
    end)
    |> Enum.uniq()
  end

  @doc """
  cache1 快速查询 的table定义 解析, 返回示例
      cache1_table("animal", name, type, age)

      %{
        "animal" => %{
          index_row_name: %{1 => :name, 2 => :type, 3 => :age},
          q1: {:"$1", :"$2", :"$3"},
          row_name_index: %{age: :"$3", name: :"$1", type: :"$2"},
          row_name_index2: %{age: 3, name: 1, type: 2},
          rows: [:name, :type, :age],
          rows_string: ["name", "type", "age"],
          rows_tuple_string: {"name", "type", "age"}
        },
      }
  """
  def get_cache1_table(parser) do
    parser
    |> Enum.filter(fn
      {:., _line, {:NAME, _, :cache1_table}, {:functioncall, _, _}} -> true
      _ -> false
    end)
    |> Enum.reduce(%{}, fn {:., _line, {:NAME, _, :cache1_table},
                            {:functioncall, _, [{_, _, table_name} | table_rows]}},
                           acc ->
      row_map =
        table_rows
        |> Enum.reduce(
          {1, %{index_row_name: %{}, row_name_index: %{}, row_name_index2: %{}, rows: [], q1: {}}},
          fn {_, _, row_name}, {index, acc} ->
            {index + 1,
             acc
             |> Map.put(:index_row_name, acc.index_row_name |> Map.put(index, row_name))
             |> Map.put(
               :row_name_index,
               acc.row_name_index |> Map.put(row_name, "$#{index}" |> String.to_atom())
             )
             |> Map.put(
               :row_name_index2,
               acc.row_name_index2 |> Map.put(row_name, index)
             )
             |> Map.put(:rows, acc.rows ++ [row_name])
             |> Map.put(:q1, Tuple.append(acc.q1, "$#{index}" |> String.to_atom()))}
          end
        )
        |> elem(1)

      rows_string =
        row_map.rows
        |> Enum.map(fn k ->
          k |> Atom.to_string()
        end)

      row_map =
        row_map
        |> Map.put(:rows_string, rows_string)
        |> Map.put(:rows_tuple_string, rows_string |> List.to_tuple())

      acc
      |> Map.put(table_name, row_map)
    end)
  end

  @doc """
  cache1 快速查询 的query定义 解析, 返回示例
    %{
      "q_animal" => %{
        conditions: [[{:"/=", :name, 1}, {:>, :age, 2}]],
        table_name: "animal"
      }
    }
  """
  def get_cache1_def_query(parser) do
    parser
    |> Enum.filter(fn
      {:., _line, {:NAME, _, :cache1_def_query}, {:functioncall, _, _}} -> true
      _ -> false
    end)
    |> Enum.reduce(%{}, fn {:., _line, {:NAME, _, :cache1_def_query},
                            {:functioncall, _,
                             [
                               {_, _, table_name},
                               {_, _, query_id},
                               {:STRING, _, condition_script}
                             ]}},
                           acc ->
      acc
      |> Map.put(
        query_id,
        %{
          table_name: table_name,
          conditions: parser_cache1_query_conditions(condition_script)
        }
      )
    end)
  end

  @doc """
  cache1 快速查询 的query定义 中 条件判断部分是字符串, 将其合并成lua script 做二次 解析
  """
  def parser_cache1_query_conditions(condition_script) do
    case parse("ok(#{condition_script})") do
      {:ok, [{:., _line, {:NAME, _, :ok}, {:functioncall, _, conditions}}]} ->
        conditions
        |> Enum.map(fn c ->
          gen_cache1_query_fun(c) |> List.flatten()
        end)

      _ ->
        []
    end
  end

  @doc """
  cache1 快速查询 的query定义 解析
  """
  def gen_cache1_query_fun({:op, _, :and, left, right}) do
    [gen_cache1_query_fun(left), gen_cache1_query_fun(right)]
  end

  def gen_cache1_query_fun({:op, _, :"~=", {:NAME, _, row_name}, {:STRING, _, input_num}}) do
    [{:"/=", row_name, input_num |> KunERAUQS.D0_f.string_to_int()}]
  end

  def gen_cache1_query_fun({:op, _, op, {:NAME, _, row_name}, {:STRING, _, input_num}})
      when op in [:>, :>=, :==, :<, :<=] do
    [{op, row_name, input_num |> KunERAUQS.D0_f.string_to_int()}]
  end
end
