defmodule Exdns.Events do
  @moduledoc """
  Event manager for events fired by exdns.
  """

  use GenEvent
  require Logger

  # Public API

  def start_link() do
    GenEvent.start_link(name: Exdns.Events)
  end

  def notify(message) do
    GenEvent.notify(Exdns.Events, message)
  end

  def add_handler(module, args) do
    GenEvent.add_handler(Exdns.Events, module, args)
  end

  # GenEvent callbacks
  def init(_) do
    {:ok, %{:servers_running => false}}
  end

  def handle_call(:get_servers_running, state) do
    {:ok, Map.get(state, :servers_running), state}
  end

  # Event handlers

  def handle_event(:start_servers, state) do
    if Map.get(state, :servers_running) do
      Exdns.Events.notify(:servers_already_started)
      {:ok, state}
    else
      Exdns.Server.Supervisor.start_link()
      Exdns.Events.notify(:servers_started)
      {:ok, %{state | servers_running: true}}
    end
  end

  def handle_event(:stop_servers, state) do
    {:ok, %{state | servers_running: false}}
  end

  def handle_event({:end_udp, [{:host, _host}]}, state) do
    :folsom_metrics.notify({:udp_request_meter, 1})
    :folsom_metrics.notify({:udp_request_counter, {:inc, 1}})
    {:ok, state}
  end

  def handle_event({:end_tcp, [{:host, _host}]}, state) do
    :folsom_metrics.notify({:tcp_request_meter, 1})
    :folsom_metrics.notify({:tcp_request_counter, {:inc, 1}})
    {:ok, state}
  end

  def handle_event({:udp_error, reason}, state) do
    :folsom_metrics.notify({:udp_error_meter, 1})
    :folsom_metrics.notify({:udp_error_history, reason})
    {:ok, state}
  end

  def handle_event({:tcp_error, reason}, state) do
    :folsom_metrics.notify({:tcp_error_meter, 1})
    :folsom_metrics.notify({:tcp_error_history, reason})
    {:ok, state}
  end

  def handle_event({:refused_response, questions}, state) do
    :folsom_metrics.notify({:refused_response_meter, 1})
    :folsom_metrics.notify({:refused_response_counter, {:inc, 1}})
    Logger.debug("Refused response: #{inspect questions}")
    {:ok, state}
  end

  def handle_event({:empty_response, message}, state) do
    :folsom_metrics.notify({:empty_response_meter, 1})
    :folsom_metrics.notify({:empty_response_counter, {:inc, 1}})
    Logger.info("Empty response: #{inspect message}")
    {:ok, state}
  end

  def handle_event({:dnssec_request, _host, _qname}, state) do
    :folsom_metrics.notify(:dnssec_request_meter, 1)
    :folsom_metrics.notify(:dnssec_request_counter, {:inc, 1})
    {:ok, state}
  end

  def handle_event(_event, state) do
    {:ok, state}
  end
end
