defmodule Exdns.PacketCache do
  @moduledoc """
  Short-lived packet cache for faster responses of questions that were recently answered.
  """

  use GenServer

  @enabled true
  @default_ttl 20
  @sweep_interval 1000 * 60 * 3 # Every 3 minutes

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: Exdns.PacketCache)
  end

  def get(question) do
    get(question, :unknown)
  end

  def get(question, _host) do
    case Exdns.Storage.select(:packet_cache, question) do
      [{^question, {response, expires_at}}] ->
        if Exdns.timestamp() > expires_at do
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
      GenServer.call(Exdns.PacketCache, {:set_packet, [question, message]})
    else
      :ok
    end
  end

  def sweep() do
    GenServer.call(Exdns.PacketCache, :sweep)
  end

  def clear() do
    GenServer.call(Exdns.PacketCache, :clear)
  end

  def stop() do
    GenServer.call(Exdns.PacketCache, :stop)
  end

  # Server callbacks

  def init([]) do
    init([@default_ttl])
  end

  def init([ttl]) do
    Exdns.Storage.create(:packet_cache)
    {:ok, tref} = :timer.apply_interval(@sweep_interval, Exdns.PacketCache, :sweep, [])
    {:ok, %{ttl: ttl, tref: tref}}
  end

  def handle_call({:set_packet, [question, response]}, _from, state) do
    Exdns.Storage.insert(:packet_cache, {question, {response, Exdns.timestamp() + Map.get(state, :ttl)}})
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    Exdns.Storage.empty_table(:packet_cache)
    {:reply, :ok, state}
  end

  def handle_call(:sweep, _from, state) do
    Exdns.Storage.select(:packet_cache, [{{:"$1", {:_, :"$2"}}, [{:<, :"$2", Exdns.timestamp() - 10}], [:"$1"]}], :infinite) |>
      Enum.each(fn(k) -> Exdns.Storage.delete(:packet_cache, k) end)
    {:reply, :ok, state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end
end
