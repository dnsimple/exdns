defmodule ExDNS.Supervisor do
  @moduledoc """
  ExDNS application supervisor
  """

  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: ExDNS.Supervisor)
  end

  def init(_args) do
    children = [
      worker(ExDNS.Events, []),
      worker(ExDNS.Zone.Cache, []),
      worker(ExDNS.Zone.Registry, []),
      # worker(ExDNS.ZoneEncoder, []),
      worker(ExDNS.PacketCache, []),
      worker(ExDNS.QueryThrottle, []),
      worker(ExDNS.Handler.Registry, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

end
