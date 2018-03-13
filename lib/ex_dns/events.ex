defmodule ExDNS.Events do
  @moduledoc """
  Event manager for events fired by ExDNS
  """

  use GenServer
  require Logger
  alias __MODULE__
  alias ExDNS.EventsHandler


  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: Events)
  end

  def init(_) do
    Logger.info(IO.ANSI.green <> "Starting the Events Handler" <> IO.ANSI.reset())
    Registry.start_link(keys: :duplicate, name: EventsHandler)
    {:ok, %{servers_running: false}}
  end

  def notify(topic) do
    GenServer.cast(Events, topic)
  end

  def broadcast(topic, message) do
    Registry.dispatch(__MODULE__, topic, fn entries ->
      for {pid, _} <- entries, do: GenServer.cast(pid, {topic, message})
    end)
  end

  def subscribe(topic) do
    Registry.register(EventsHandler, topic, [])
  end

  def handle_cast(:start_servers, state) do
    if Map.get(state, :servers_running) do
      ExDNS.Events.notify(:servers_already_started)
      {:noreply, state}
    else
      ExDNS.Server.Supervisor.start_link()
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

  def handle_cast(_event, state) do
    {:noreply, state}
  end
end
