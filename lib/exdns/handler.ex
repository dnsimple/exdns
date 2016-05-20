defmodule Exdns.Handler do
  require Logger
  require Record
  require Exdns.Records

  def handle({:trailing_garbage, message, _}, context) do
    handle(message, context)
  end

  def handle(message, context = {_, host}) when Record.is_record(message, :dns_message) do
    handle(message, host, Exdns.QueryThrottle.throttle(message, context))
  end

  def handle(bad_message, {_, host}) do
    # Logger.error("Received a bad message: #{inspect bad_message} from #{host}")
    bad_message
  end

  # Private functions

  defp handle(message, host, {:throttled, host, _req_count}) do
    :folsom_metrics.notify({:request_throttled_counter, {:inc, 1}})
    :folsom_metrics.notify({:request_throttled_meter, 1})
    Exdns.Records.dns_message(message, tc: true, aa: true, rc: :dns_terms_const.dns_rcode_noerror)
  end

  defp handle(message, host, _) do
    Logger.debug("Questions: #{inspect Exdns.Records.dns_message(message, :questions)}")
    Exdns.Events.notify({:start_handle, [{:host, host}, {:message, message}]})
    response = :folsom_metrics.histogram_timed_update(:request_handled_histogram, __MODULE__, :do_handle, [message, host])
    Exdns.Events.notify({:end_handle, [{:host, host}, {:message, message}, {:response, response}]})
    response
  end

  # This is only public because it is used through Folsom and thus triggers a warning of non-use unless
  # it is public.
  def do_handle(message, host) do
    handle_message(message, host) |> complete_response
  end

  defp handle_message(message, host) do
    case Exdns.PacketCache.get(Exdns.Records.dns_message(message, :questions), host) do
      {:ok, cached_response} ->
        Exdns.Events.notify({:packet_cache_hit, [{:host, host}, {:message, message}]})
        Exdns.Records.dns_message(cached_response, id: Exdns.Records.dns_message(message, :id))
      {:error, reason} ->
        Exdns.Events.notify({:packet_cache_miss, [{:reason, reason}, {:host, host}, {:message, message}]})
        handle_packet_cache_miss(message, get_authority(message), host) # SOA lookup
    end
  end

  defp handle_packet_cache_miss(message, [], _host) do
    if Exdns.Config.use_root_hints() do
      {authority, additional} = Exdns.Records.root_hints()
      Exdns.Records.dns_message(message, aa: false, rc: :dns_terms_const.dns_rcode_refused, authority: authority, additional: additional)
    else
      Exdns.Records.dns_message(message, aa: false, rc: :dns_terms_const.dns_rcode_refused)
    end
  end

  defp handle_packet_cache_miss(message, authority, host) do
    safe_handle_packet_cache_miss(Exdns.Records.dns_message(message, ra: false), authority, host)
  end

  defp safe_handle_packet_cache_miss(message, authority, host) do
    if Application.get_env(:exdns, :catch_exceptions) do
      try do
        message = Exdns.Resolver.resolve(message, authority, host)
        maybe_cache_packet(message, Exdns.Records.dns_message(message, :aa))
      rescue
        exception ->
          # Logger.error("Error answering request: #{inspect exception}")
          Exdns.Records.dns_message(message, aa: false, rc: :dns_terms_const.dns_rcode_servfail)
      end
    else
      message = Exdns.Resolver.resolve(message, authority, host)
      maybe_cache_packet(message, Exdns.Records.dns_message(message, :aa))
    end
  end

  defp maybe_cache_packet(message, true) do
    Exdns.PacketCache.put(Exdns.Records.dns_message(message, :questions), message)
    message
  end

  defp maybe_cache_packet(message, false) do
    message
  end

  defp get_authority(message_or_name) do
    case Exdns.ZoneCache.get_authority(message_or_name) do
      {:ok, authority} -> [authority]
      {:error, _} -> []
    end
  end

  defp complete_response(message) do
    notify_empty_response(Exdns.Records.dns_message(message,
      anc: length(Exdns.Records.dns_message(message, :answers)),
      auc: length(Exdns.Records.dns_message(message, :authority)),
      adc: length(Exdns.Records.dns_message(message, :additional)),
      qr: true
    ))
  end

  defp notify_empty_response(message) do
    rr_count = Exdns.Records.dns_message(message, :anc) + Exdns.Records.dns_message(message, :auc) + Exdns.Records.dns_message(message, :adc)
    dns_rcode_refused = :dns_terms_const.dns_rcode_refused()

    case {Exdns.Records.dns_message(message, :rc), rr_count} do
      {^dns_rcode_refused, _} ->
        Exdns.Events.notify({:refused_response, Exdns.Records.dns_message(message, :questions)})
        message
      {_, 0} ->
        Exdns.Events.notify({:empty_response, message})
        message
      _ ->
        message
    end
  end
end
