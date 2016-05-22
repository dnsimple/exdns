defmodule Exdns.Server.Supervisor do
  use Supervisor
  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: Exdns.Server.Supervisor)
  end

  def stop do
    Supervisor.stop(Exdns.Server.Supervisor)
    Exdns.Events.notify(:stop_servers)
    :ok
  end

  def stop_children do
    Supervisor.which_children(Exdns.Server.Supervisor) |>
      Enum.map(fn(c) -> Supervisor.terminate_child(Exdns.Server.Supervisor, c) end)
    :ok
  end

  def init(_) do
    supervise(define_servers(Exdns.Config.get_servers()), strategy: :one_for_one)
  end

  def define_servers([]) do
    [
      worker(Exdns.Server.UdpServer, [:udp_inet, :inet, Exdns.Config.get_address(:inet), Exdns.Config.get_port()], id: :udp_inet, restart: :permanent, timeout: 5000),
      worker(Exdns.Server.UdpServer, [:udp_inet6, :inet6, Exdns.Config.get_address(:inet6), Exdns.Config.get_port()], id: :udp_inet6, restart: :permanent, timeout: 5000)
      #worker(Exdns.Server.TcpServer, [:tcp_inet, :inet, Exdns.Config.get_address(:inet), Exdns.Config.get_port()], id: :tcp_inet, restart: :permanent, timeout: 5000),
      #worker(Exdns.Server.TcpServer, [:tcp_inet6, :inet6], id: :tcp_inet6, restart: :permanent, timeout: 5000),
    ]
  end
end
