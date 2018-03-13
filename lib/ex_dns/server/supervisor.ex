defmodule ExDNS.Server.Supervisor do
  @moduledoc """
  Supervisor for server processes, including UDP and TCP server processes.
  """

  use Supervisor
  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def stop do
    Supervisor.stop(ExDNS.Server.Supervisor)
    ExDNS.Events.notify(:stop_servers)
    :ok
  end

  def stop_children do
    Supervisor.which_children(ExDNS.Server.Supervisor) |>
      Enum.map(fn(c) -> Supervisor.terminate_child(ExDNS.Server.Supervisor, c) end)
    :ok
  end

  def init(_) do
    Logger.info(IO.ANSI.green <> "Starting the Server Supervisor" <> IO.ANSI.reset())
    servers = ExDNS.Config.servers
    if servers == [] and Mix.env != :test, do: Logger.warn("No servers are specified in your config")
    Enum.map(servers, &define_server/1) |> supervise(strategy: :one_for_one)
  end

  def define_server(%{name: name, type: type, address: raw_ip, port: port, family: family}) do
    case :inet_parse.address(to_charlist(raw_ip)) do
      {:ok, address} -> worker(type, [name, family, address, port], id: name, restart: :permanent, timeout: 5000)
      {:error, reason} -> raise ArgumentError, reason
    end
  end
end
