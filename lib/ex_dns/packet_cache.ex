defmodule ExDNS.PacketCache do
  @moduledoc """
  Short-lived packet cache for faster responses of questions that were recently answered.
  """

  use GenServer
  require Logger

  @enabled true
  @default_ttl 20
  @sweep_interval 1000 * 60 * 3 # Every 3 minutes

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__) 
  end

  def get(question) do
    get(question, :unknown)
  end

  def get(question, _host) do
    case ExDNS.Storage.select(:packet_cache, question) do
      [{^question, {response, expires_at}}] ->
        if ExDNS.timestamp() > expires_at do
          :folsom_metrics.notify(:cache_expired_meter, 1)
          {:error, :cache_expired}
        else
          :folsom_metrics.notify(:cache_hit_meter, 1)
          {:ok, response}
        end
      _ ->
        :folsom_metrics.notify(:cache_miss_meter, 1)
        {:error, :cache_miss}
    end
  end

  def put(question, message) do
    if @enabled do
      GenServer.call(ExDNS.PacketCache, {:set_packet, [question, message]})
    else
      :ok
    end
  end

  def sweep() do
    GenServer.call(ExDNS.PacketCache, :sweep)
  end

  def clear() do
    GenServer.call(ExDNS.PacketCache, :clear)
  end

  def stop() do
    GenServer.call(ExDNS.PacketCache, :stop)
  end

  # Server callbacks

  def init([]) do
    Logger.info(IO.ANSI.green <> "Starting the Packet Cache" <> IO.ANSI.reset())
    init([@default_ttl])
  end

  def init([ttl]) do
    ExDNS.Storage.create(:packet_cache)
    {:ok, tref} = :timer.apply_interval(@sweep_interval, ExDNS.PacketCache, :sweep, [])
    {:ok, %{ttl: ttl, tref: tref}}
  end

  def handle_call({:set_packet, [question, response]}, _from, state) do
    ExDNS.Storage.insert(:packet_cache, {question, {response, ExDNS.timestamp() + Map.get(state, :ttl)}})
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    ExDNS.Storage.empty_table(:packet_cache)
    {:reply, :ok, state}
  end

  def handle_call(:sweep, _from, state) do
    ExDNS.Storage.select(:packet_cache, [{{:"$1", {:"_", :"$2"}}, [{:<, :"$2", ExDNS.timestamp() - 10}], [:"$1"]}], :infinite) |>
      Enum.each(fn(k) -> ExDNS.Storage.delete(:packet_cache, k) end)
    {:reply, :ok, state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end
end
