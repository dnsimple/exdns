defmodule Exdns.Supervisor do
  require Logger

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: Exdns.Supervisor)
  end

  def init(_args) do
    children = [
      worker(Exdns.Events, []),
      worker(Exdns.ZoneCache, []),
      # worker(Exdns.ZoneParser, []),
      # worker(Exdns.ZoneEncoder, []),
      worker(Exdns.PacketCache, []),
      worker(Exdns.QueryThrottle, []),
      worker(Exdns.Handler.Registry, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

end
