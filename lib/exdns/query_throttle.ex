defmodule Exdns.QueryThrottle do
  @moduledoc """
  Implements query throttling.

  At the moment this throttle only throttles ANY queries over UDP.
  """

  use GenServer
  require Exdns.Records

  @limit 1
  @expiration 60
  @enabled true
  @sweep_interval 1000 * 60 * 5

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: Exdns.QueryThrottle)
  end

  def throttle(_message, {:tcp, _host}) do
    :ok
  end

  def throttle(message, {_, host}) do
    if @enabled do
      questions = Exdns.Records.dns_message(message, :questions)
      matches = Enum.filter(questions, fn(q) -> Exdns.Records.dns_query(q, :type) == :dns_terms_const.dns_type_any end)
      case matches do
        [] -> :ok
        _ -> record_request(maybe_throttle(host))
      end
    else
      :ok
    end
  end

  def clear() do
    GenServer.call(Exdns.QueryThrottle, :clear)
  end

  def sweep() do
    GenServer.call(Exdns.QueryThrottle, :sweep)
  end

  def stop() do
    GenServer.call(Exdns.QueryThrottle, :stop)
  end

  # GenServer callbacks

  def init([]) do
    Exdns.Storage.create(:host_throttle)
    {:ok, tref} = :timer.apply_interval(@sweep_interval, Exdns.QueryThrottle, :sweep, [])
    {:ok, %{tref: tref}}
  end
  def handle_call(:clear, _from, state) do
    Exdns.Storage.empty_table(:host_throttle)
    {:reply, :ok, state}
  end
  def handle_call(:sweep, _from, state) do
    Exdns.Storage.select(:host_throttle, [{{:"$1", {:"_", :"$2"}}, [{:<, :"$2", Exdns.timestamp() - @expiration}], [:"$1"]}], :infinite) |>
      Enum.each(fn(k) -> Exdns.Storage.delete(:host_throttle, k) end)
    {:reply, :ok, state}
  end
  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  # Private functions

  defp maybe_throttle(host) do
    case Exdns.Storage.select(:host_throttle, host) do
      [{^host, {req_count, last_request_at}}] ->
        case is_throttled(host, req_count, last_request_at) do
          {true, new_req_count} -> {:throttled, host, new_req_count}
          {false, new_req_count} -> {:ok, host, new_req_count}
        end
      [] ->
        {:ok, host, 1}
    end
  end

  defp record_request({throttle_response, host, req_count}) do
    Exdns.Storage.insert(:host_throttle, {host, {req_count, Exdns.timestamp()}})
    {throttle_response, host, req_count}
  end

  defp is_throttled({127, 0, 0, 1}, req_count, _) do
    {false, req_count + 1}
  end
  defp is_throttled(host, req_count, last_request_at) do
    exceeds_limit = req_count >= @limit
    expired = Exdns.timestamp() - last_request_at > @expiration
    if expired do
      Exdns.Storage.delete(:host_throttle, host)
      {false, 1}
    else
      {exceeds_limit, req_count + 1}
    end
  end
end
