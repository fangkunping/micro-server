defmodule MicroServer.RamUtility do
  require Kunerauqs.GenRamFunction

  Kunerauqs.GenRamFunction.gen_def(
    write_concurrency: true,
    read_concurrency: true
  )

  def init_self() do
    init_ram()
  end
end

