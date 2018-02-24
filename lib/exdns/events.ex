defmodule Exdns.Events do
  @moduledoc """
  Event manager for events fired by exdns.
  """

  @timeout 30_000

  require Logger

  # Public API

  def start_link() do
    import Supervisor.Spec
    child = worker(GenServer, [], restart: :temporary)
    Supervisor.start_link([child], strategy: :simple_one_for_one, name: __MODULE__)
  end

  def stop() do
    for {_, pid, _, _} <- Supervisor.which_children(__MODULE__) do
      GenServer.stop(pid, :normal, @timeout)
    end
    Supervisor.stop(__MODULE__)
  end

  def notify(message) do
    for {_, pid, _, _} <- Supervisor.which_children(__MODULE__) do
      GenServer.cast(pid, message)
    end
    :ok
  end

  def add_handler(handler, opts) do
    Supervisor.start_child(__MODULE__, [handler, opts])
  end

  # Event handlers

  def handle_cast(:start_servers, state) do
    Exdns.Server.Supervisor.start_link()
    notify(:servers_started)
    {:noreply, %{state | servers_running: true}}
  end

  def handle_cast(:stop_servers, state) do
    {:noreply, %{state | servers_running: false}}
  end

  def handle_cast({:end_udp, [{:host, _host}]}, state) do
    :folsom_metrics.notify({:udp_request_meter, 1})
    :folsom_metrics.notify({:udp_request_counter, {:inc, 1}})
    {:noreply, state}
  end

  def handle_cast({:end_tcp, [{:host, _host}]}, state) do
    :folsom_metrics.notify({:tcp_request_meter, 1})
    :folsom_metrics.notify({:tcp_request_counter, {:inc, 1}})
    {:noreply, state}
  end

  def handle_cast({:udp_error, reason}, state) do
    :folsom_metrics.notify({:udp_error_meter, 1})
    :folsom_metrics.notify({:udp_error_history, reason})
    {:noreply, state}
  end

  def handle_cast({:tcp_error, reason}, state) do
    :folsom_metrics.notify({:tcp_error_meter, 1})
    :folsom_metrics.notify({:tcp_error_history, reason})
    {:ok, state}
  end

  def handle_cast({:refused_response, questions}, state) do
    :folsom_metrics.notify({:refused_response_meter, 1})
    :folsom_metrics.notify({:refused_response_counter, {:inc, 1}})
    Logger.debug("Refused response: #{inspect questions}")
    {:noreply, state}
  end

  def handle_cast({:empty_response, message}, state) do
    :folsom_metrics.notify({:empty_response_meter, 1})
    :folsom_metrics.notify({:empty_response_counter, {:inc, 1}})
    Logger.info("Empty response: #{inspect message}")
    {:noreply, state}
  end

  def handle_cast({:dnssec_request, _host, _qname}, state) do
    :folsom_metrics.notify(:dnssec_request_meter, 1)
    :folsom_metrics.notify(:dnssec_request_counter, {:inc, 1})
    {:noreply, state}
  end

  def handle_cast(_event, state) do
    {:noreply, state}
  end
end
