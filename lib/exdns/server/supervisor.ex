defmodule Exdns.Server.Supervisor do
  @moduledoc """
  Supervisor for server processes, including UDP and TCP server processes.
  """

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
    _ =
      Exdns.Server.Supervisor
      |> Supervisor.which_children()
      |> Enum.map(fn c -> Supervisor.terminate_child(Exdns.Server.Supervisor, c) end)

    :ok
  end

  def init(_) do
    servers = Exdns.Config.servers()

    if servers == [] and Mix.env() != :test,
      do: Logger.warn("No servers are specified in your config")

    servers
    |> Enum.map(&define_server/1)
    |> supervise(strategy: :one_for_one)
  end

  def define_server(%{name: name, type: type, address: raw_ip, port: port, family: family}) do
    case :inet_parse.address(to_charlist(raw_ip)) do
      {:ok, address} ->
        worker(type, [name, family, address, port], id: name, restart: :permanent, timeout: 5000)

      {:error, reason} ->
        raise ArgumentError, reason
    end
  end
end
