defmodule ExDNS.Events do
  @moduledoc """
  Event manager for events fired by exdns.
  """

  use GenServer
  require Logger

  # Public API

  def start_link([]) do
    GenEvent.start_link(name: ExDNS.Events)
  end

  def notify(message) do
    GenEvent.notify(ExDNS.Events, message)
  end

  # GenEvent callbacks
  def init(_) do
    {:noreply, %{:servers_running => false}}
  end

  def handle_call(:get_servers_running, state) do
    {:noreply, Map.get(state, :servers_running), state}
  end

  # Event handlers

  def handle_cast(:start_servers, state) do
    if Map.get(state, :servers_running) do
      ExDNS.Events.notify(:servers_already_started)
      {:noreply, state}
    else
      ExDNS.Server.Supervisor.start_link([])
      ExDNS.Events.notify(:servers_started)
      {:noreply, %{state | servers_running: true}}
    end
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
    {:noreply, state}
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

  def handle_cast(_cast, state) do
    {:noreply, state}
  end
end
