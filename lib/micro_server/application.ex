defmodule MicroServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    MicroServer.RuntimeExsUtility.init_self()
    MicroServer.RamUtility.init_self()
    MicroServer.LuaLibUtility.init_self()
    MicroServer.AppWork.init_self()
    MicroServer.ServerWork.init_self()
    MicroServer.LuaLib.Basic.init_self()

    # poolboy
    poolboy_specs =
      apply(MicroServer.Runtime.Config, :poolboy, [])
      |> Enum.map(fn [{:name, {_, name}} | _] = poolboy_conf ->
        :poolboy.child_spec(name, poolboy_conf)
      end)

    # List all child processes to be supervised
    children =
      [
        # Starts a worker by calling: MicroServer.Worker.start_link(arg)
        # {MicroServer.Worker, arg},
        MicroServer.Repo,
        MicroServer.ServerSupervisor,
        MicroServer.AppSupervisor,
        MicroServer.RemotingWork,
        MicroServer.AppUtilityWork,
        MicroServer.LogWork
      ] ++ poolboy_specs ++ Kunerauqs.init_module()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MicroServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
