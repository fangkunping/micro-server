defmodule MicroServer.Remoting.Script do
  alias MicroServer.Repo
  alias MicroServer.Script
  import Ecto.Query, only: [from: 2]
  require Ecto.Query

  @doc """
  获取脚本
  """
  @spec get_scripts(integer) :: list
  def get_scripts(access_party_id) do
    from(
      s in Script,
      where: s.access_partys_id == ^access_party_id,
      select: s
    )
    |> Repo.all()
  end

  @doc """
  通过id获取脚本内容
  """
  @spec get_script(integer, integer) :: map | nil
  def get_script(access_party_id, script_id) do
    Repo.get_by(Script, id: script_id, access_partys_id: access_party_id)
  end

  @spec get_script_by_name(integer, String.t()) :: map | nil
  def get_script_by_name(access_party_id, script_name) do
    from(s in Script,
      select: s,
      where: s.name == ^script_name and s.access_partys_id == ^access_party_id
    )
    |> Repo.all()
  end

  @doc """
  更新脚本
  """
  @spec update_script(integer, map) :: {:ok, any} | {:error, any}
  def update_script(access_party_id, script_params) do
    script_id =
      case script_params["id"] do
        v when is_number(v) ->
          v |> KunERAUQS.D0_f.number_to_int()

        v when is_binary(v) ->
          v |> String.to_integer()
      end

    script =
      Repo.get_by(Script,
        id: script_id,
        access_partys_id: access_party_id
      )

    changeset = Script.changeset(script, script_params)
    Repo.update(changeset)
  end

  @doc """
  创建新脚本
  """
  @spec create_script(integer, map) :: :ok | {:error, String.t()}
  def create_script(access_party_id, script_params) do
    # 获取 access_party 的script数量
    script_count =
      from(
        s in Script,
        where: s.access_partys_id == ^access_party_id,
        select: count(s.id)
      )
      |> Repo.one()

    # 数量超过限制
    script_create_max = Application.get_env(:micro_server, :script_create_max)

    if script_count < script_create_max do
      changeset =
        Script.changeset(%Script{}, script_params |> Map.put("access_partys_id", access_party_id))

      case Repo.insert(changeset) do
        {:ok, script} ->
          {:ok, script}

        {:error, _} ->
          {:error, "Database error"}
      end
    else
      {:error, "Reach maximum limit"}
    end
  end

  @doc """
  删除脚本
  """
  @spec delete_script(integer, integer) :: {:ok, any} | {:error, any}
  def delete_script(access_party_id, script_id) do
    script = Repo.get_by(Script, id: script_id, access_partys_id: access_party_id)
    Repo.delete(script)
  end

end
