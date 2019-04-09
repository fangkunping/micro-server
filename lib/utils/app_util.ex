defmodule MicroServer.AppUtility do

  alias Kunerauqs.EtsProxy
  alias MicroServer.CommonUtility

  @spec start_app(integer) :: {:ok, pid} | {:error, term}
  def start_app(access_party_id) do
    MicroServer.AppUtilityWork |> GenServer.call({:start_app, access_party_id})
  end

  @spec app_exist?(integer) :: true | false
  def app_exist?(app_id) do
    # app work 的ram中是否存在 app_id 且 其对应的pid 活着
    if get_app_pid(app_id) == nil do
      false
    else
      true
    end
  end

  @spec get_app_pid(integer) :: nil | pid
  def get_app_pid(access_party_id) do
    case EtsProxy.read(MicroServer.AppWork, access_party_id) do
      nil ->
        nil

      server_pid ->
        if CommonUtility.pid_alive?(server_pid) do
          server_pid
        else
          nil
        end
    end
  end
end
