defmodule Exdns.Server.TcpServer do
  @moduledoc """
  Server for receiving TCP packets.
  """
  @behaviour :gen_nb_server

  require Logger

  def start_link(name, inet_family, address, port) do
    Logger.debug("Starting TCP server for #{inet_family} on address #{inspect address} port #{port}")
    :gen_nb_server.start_link(__MODULE__, address, port, [])
  end

  def stop(name) do

  end

  # GenServer callbacks

  def init([]) do
    {:ok, %{workers: Exdns.Worker.make_workers(:queue.new())}}
  end

  def handle_call(_message, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_message, state) do
    {:noreply, state}
  end

  def handle_info(msg = {:tcp, socket, bin}, state) do
    response = :folsom_metrics.histogram_timed_update(:tcp_handoff_histogram, Exdns.Server.TcpServer, :handle_request, [socket, bin, state])
    :inet.setopts(socket, [{:active, :once}])
    {:noreply, state}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  def terminate(_reason, state) do
    :ok
  end

  def sock_opts() do
    [:binary, {:reuseaddr, true}]
  end

  def new_connection(socket, state) do
    :inet.setopts(socket, [{:active, :once}])
    {:ok, state}
  end

  def handle_request(socket, bin, state) do
    case :queue.out(Map.get(state, :workers)) do
      {{:value, worker}, queue} ->
        GenServer.call(worker, {:tcp_query, socket, bin})
        {:noreply, %{state | workers: :queue.in(worker, queue) }}
      {:empty, _queue} ->
        :folsom_metrics.notify({:packet_dropped_empty_queue_counter, {:inc, 1}})
        :folsom_metrics.notify({:packet_dropped_empty_queue_meter, 1})
        # Logger.info("Queue is empty, dropping packet")
        {:noreply, state}
    end
  end
end
