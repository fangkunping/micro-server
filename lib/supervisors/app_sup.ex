defmodule MicroServer.AppSupervisor do
  use Supervisor

  def start_link(_opt) do
    # Supervisor.start_link(监督模块名称, 监督模块.init/1 函数的参数)
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      worker(MicroServer.AppWork, [], restart: :temporary) #:transient
    ]

    # supervise/2 is imported from Supervisor.Spec
    supervise(children, strategy: :simple_one_for_one)
  end


end
