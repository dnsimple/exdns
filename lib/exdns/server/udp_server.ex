defmodule Exdns.Server.UdpServer do
  @moduledoc """
  Server for receiving UDP packets.
  """

  use GenServer
  require Logger

  def start_link(name, inet_family, address, port) do
    GenServer.start_link(__MODULE__, [inet_family, address, port], name: name)
  end

  def start_link(name, inet_family, address, port, socket_opts) do
    GenServer.start_link(__MODULE__, [inet_family, address, port, socket_opts], name: name)
  end

  def stop(name) do
    GenServer.call(name, :stop)
  end

  # GenServer callbacks 

  def init([inet_family, address, port]) do
    init([inet_family, address, port, []])
  end

  def init([inet_family, address, port, socket_opts]) do
    {:ok, socket} = start(address, port, inet_family, socket_opts)
    {:ok, %{address: address, port: port, socket: socket, workers: Exdns.Worker.make_workers(:queue.new())}}
  end

  def handle_call(:stop, _from, state) do
    cleanup(state[:socket])
    {:stop, :normal, :ok, state}
  end

  def handle_cast(_message, state) do
    {:noreply, state}
  end

  def handle_info(:timeout, state) do
    {:noreply, state}
  end

  def handle_info({:udp, socket, host, port, bin}, state) do
    response = :folsom_metrics.histogram_timed_update(:udp_handoff_histogram, Exdns.Server.UdpServer, :handle_request, [socket, host, port, bin, state])
    :inet.setopts(Map.get(state, :socket), [{:active, :once}])
    response
  end

  def terminate(_reason, state) do
    cleanup(state[:socket])
    :ok
  end

  defp cleanup(socket) do
    :gen_udp.close(socket)
    :ok
  end

  # This function executes in a single process and thus must return fast. The execution time of this
  # function impacts the total QPS of the system.
  def handle_request(socket, host, port, bin, state) do
    case :queue.out(Map.get(state, :workers)) do
      {{:value, worker}, queue} ->
        GenServer.cast(worker, {:udp_query, socket, host, port, bin})
        {:noreply, %{state | workers: :queue.in(worker, queue) }}
      {:empty, _queue} ->
        :folsom_metrics.notify({:packet_dropped_empty_queue_counter, {:inc, 1}})
        :folsom_metrics.notify({:packet_dropped_empty_queue_meter, 1})
        # Logger.info("Queue is empty, dropping packet")
        {:noreply, state}
    end
  end

  # Private functions
  defp start(address, port, inet_family, socket_opts) do
    case :gen_udp.open(port, [:binary, {:active, :once}, {:reuseaddr, true}, {:read_packets, 1000}, {:ip, address}, inet_family|socket_opts]) do
      {:ok, socket} ->
        {:ok, socket}
      {:error, :eacces} ->
        Logger.error("Failed to open UDP socket. Need to run as sudo?")
        {:error, :eacces}
    end
  end
end
