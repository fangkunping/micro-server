defmodule MicroServer.LuaLib.Crypto do
  alias MicroServer.LuaUtility

  @doc """
  过程数据初始化函数, 在第一次获取过程数据的时候调用
  """
  @spec init_state :: map
  def init_state, do: %{}

  @doc """
  模块需要用到的lua脚本
  """
  def addtion_lua, do: ""

  @doc """
  库初始化函数, 在启动微服务的时候调用
  """
  @spec init(lua_state :: term, String.t(), integer) :: new_lua_state :: term
  def init(lua_state, _app_id, _server_id) do
    lua_state
    |> LuaUtility.set_value([:crypto], [])
    |> md5()
    |> sha256()
    |> password_hash()
    |> password_validate()
  end

  @doc """
  md5
  """
  def md5(lua_state) do
    LuaUtility.set_value(lua_state, [:crypto, :md5], fn [str], state ->
      {[str |> KunERAUQS.Extension.md5()], state}
    end)
  end

  @doc """
  sha256
  """
  def sha256(lua_state) do
    LuaUtility.set_value(lua_state, [:crypto, :sha256], fn [str], state ->
      {[:crypto.hash(:sha256, str) |> Base.encode16() |> String.downcase()], state}
    end)
  end

  @doc """
  password_hash
  """
  def password_hash(lua_state) do
    LuaUtility.set_value(lua_state, [:crypto, :password_hash], fn datas, state ->
      {str, salt_addtion} =
        case datas do
          [str] ->
            {str, ""}

          [str, salt_addtion] ->
            {str, salt_addtion}
        end

      {[Kunerauqs.ZenCartPassword.zen_encrypt_password(str, salt_addtion)], state}
    end)
  end

  @doc """
  password_validate
  """
  def password_validate(lua_state) do
    LuaUtility.set_value(lua_state, [:crypto, :password_validate], fn datas, state ->
      {plain, encrypted, salt_addtion} =
        case datas do
          [plain, encrypted] ->
            {plain, encrypted, ""}

          [plain, encrypted, salt_addtion] ->
            {plain, encrypted, salt_addtion}
        end

      {[Kunerauqs.ZenCartPassword.zen_validate_password(plain, encrypted, salt_addtion)], state}
    end)
  end
end
