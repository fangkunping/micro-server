defmodule MicroServer.LuaLibUtility do
  alias MicroServer.LuaUtility
  require Kunerauqs.GenRamFunction
  # ram 用于保存各个函数库的过程数据
  # 保存形式为 {server_id :: interger, %{atom => map}}
  # 例如:
  # {1, %{
  #   MicroServer.LuaLib.System => %{}
  # }}
  Kunerauqs.GenRamFunction.gen_def(
    write_concurrency: true,
    read_concurrency: true
  )

  def init_self() do
    init_ram()
    prepare_libs()
  end

  def prepare_libs() do
    HTTPoison.start()
  end

  @doc """
  空函数
  """
  def empty_function(lua_state, fun_name) do
    LuaUtility.set_value(lua_state, [fun_name], fn _, state ->
      {[], state}
    end)
  end

  @doc """
  附加 lua 脚本
  """
  def addtion_lua(scripts, addtion_libs) do
    [
      scripts
      | apply(MicroServer.Runtime.Config, :lua, []).extend_libs
        |> Enum.concat(addtion_libs)
        |> Enum.uniq()
        |> Enum.map(fn extend_lib ->
          try do
            apply(extend_lib, :addtion_lua, [])
          rescue
            _ ->
              ""
          end
        end)
    ]
    |> Enum.join("\n")
  end

  @doc """
  加入lua函数库 过程数据
  """
  @spec add_addtion_libs_state(String.t(), integer, lua_state :: term, list) :: lua_state :: term
  def add_addtion_libs_state(app_id, server_id, lua_state, addtion_libs) do
    apply(MicroServer.Runtime.Config, :lua, []).extend_libs
    |> Enum.concat(addtion_libs)
    |> Enum.uniq()
    |> Enum.reduce(lua_state, fn extend_lib, lua_state ->
      try do
        apply(extend_lib, :init, [lua_state, app_id, server_id])
      rescue
        _ ->
          lua_state
      end
    end)
  end

  @doc """
  初始化 过程数据
  """
  @spec init_state(integer) :: any
  def init_state(server_id) do
    write(server_id, %{})
  end

  @doc """
  销毁 过程数据
  """
  @spec destroy_state(integer) :: any
  def destroy_state(server_id) do
    delete(server_id)
  end

  @doc """
  获得 过程数据
  """
  @spec fetch_state(integer, atom) :: map
  def fetch_state(server_id, lib) do
    read!(server_id, %{})
    |> Map.get(lib, apply(lib, :init_state, []))
  end

  @doc """
  储存 过程数据
  """
  @spec store_state(integer, atom, map) :: map
  def store_state(server_id, lib, value) do
    new_state =
      read!(server_id, %{})
      |> Map.put(lib, value)

    write(server_id, new_state)
  end
end
