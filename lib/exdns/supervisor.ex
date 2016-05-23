defmodule Exdns.Supervisor do
  @moduledoc """
  Exdns application supervisor
  """

  use Supervisor
  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: Exdns.Supervisor)
  end

  def init(_args) do
    children = [
      worker(Exdns.Events, []),
      worker(Exdns.Zone.Cache, []),
      worker(Exdns.Zone.Registry, []),
      # worker(Exdns.ZoneEncoder, []),
      worker(Exdns.PacketCache, []),
      worker(Exdns.QueryThrottle, []),
      worker(Exdns.Handler.Registry, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

end
