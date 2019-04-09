defmodule MicroServer.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    # 登录名
    field(:username, :string)
    # 邮箱
    field(:email, :string)
    # 手机号
    field(:mobile, :string)
    # 是否是隐藏用户
    field(:hidden, :boolean)
    # 是否激活
    field(:is_active, :boolean)
    # 虚拟字段, 不会持久保存到数据库
    field(:password, :string, virtual: true)
    # 哈希过的密码
    field(:password_hash, :string)

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    # |> unique_constraint(:username, name: :users_username_index)
    # |> unique_constraint(:email, name: :users_email_index)
    # |> unique_constraint(:mobile, name: :users_mobile_index)
    struct
    |> cast(params, [:username, :email, :mobile, :password_hash, :is_active])
    |> validate_required([:username, :is_active])
    |> validate_length(:username, min: 3, max: 200)
    |> unique_constraint(:username, name: :users_username_index)
  end

  # 这个函数用来，过滤密码及其它信息
  def registration_changeset(struct, params) do
    struct
    |> changeset(params)
    |> cast(params, ~w(password), [])
    |> validate_required(:password)
    |> validate_length(:password, min: 4, max: 200)
    |> put_pass_hash()
  end

  # 将密码哈希化
  defp put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Kunerauqs.ZenCartPassword.zen_encrypt_password(pass))

      _ ->
        changeset
    end
  end
end
