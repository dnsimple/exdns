defmodule ExDNS.Handler do
  @moduledoc """
  Functions for handling DNS messages.

  Servers hand off to workers, which use these handler functions to answer DNS questions.
  """

  require Logger
  require Record
  require ExDNS.Records

  def handle({:trailing_garbage, message, _}, context) do
    handle(message, context)
  end
  def handle(message, context = {_, host}) when Record.is_record(message, :dns_message) do
    handle(message, host, ExDNS.QueryThrottle.throttle(message, context))
  end
  def handle(bad_message, {_, _host}) do
    bad_message
  end

  # Private functions

  defp handle(message, host, {:throttled, host, _req_count}) do
    :folsom_metrics.notify({:request_throttled_counter, {:inc, 1}})
    :folsom_metrics.notify({:request_throttled_meter, 1})
    ExDNS.Records.dns_message(message, tc: true, aa: true, rc: :dns_terms_const.dns_rcode_noerror)
  end
  defp handle(message, host, _) do
    Logger.debug("Questions: #{inspect ExDNS.Records.dns_message(message, :questions)}")
    ExDNS.Events.notify({:start_handle, [{:host, host}, {:message, message}]})
    response = :folsom_metrics.histogram_timed_update(:request_handled_histogram, __MODULE__, :do_handle, [message, host])
    ExDNS.Events.notify({:end_handle, [{:host, host}, {:message, message}, {:response, response}]})
    response
  end

  # This is only public because it is used through Folsom and thus triggers a warning of non-use unless
  # it is public.
  def do_handle(message, host) do
    handle_message(message, host) |> complete_response
  end

  defp handle_message(message, host) do
    case ExDNS.PacketCache.get(ExDNS.Records.dns_message(message, :questions), host) do
      {:ok, cached_response} ->
        ExDNS.Events.notify({:packet_cache_hit, [{:host, host}, {:message, message}]})
        ExDNS.Records.dns_message(cached_response, id: ExDNS.Records.dns_message(message, :id))
      {:error, reason} ->
        ExDNS.Events.notify({:packet_cache_miss, [{:reason, reason}, {:host, host}, {:message, message}]})
        handle_packet_cache_miss(message, get_authority(message), host) # SOA lookup
    end
  end

  defp handle_packet_cache_miss(message, [], _host) do
    if ExDNS.Config.use_root_hints? do
      {authority, additional} = ExDNS.Records.root_hints()
      ExDNS.Records.dns_message(message, aa: false, rc: :dns_terms_const.dns_rcode_refused, authority: authority, additional: additional)
    else
      ExDNS.Records.dns_message(message, aa: false, rc: :dns_terms_const.dns_rcode_refused)
    end
  end
  defp handle_packet_cache_miss(message, authority, host) do
    safe_handle_packet_cache_miss(ExDNS.Records.dns_message(message, ra: false), authority, host)
  end

  defp safe_handle_packet_cache_miss(message, authority, host) do
    if ExDNS.Config.catch_exceptions? do
      try do
        message = ExDNS.Resolver.resolve(message, authority, host)
        maybe_cache_packet(message, ExDNS.Records.dns_message(message, :aa))
      rescue
        _exception ->
          # Logger.error("Error answering request: #{inspect exception}")
          ExDNS.Records.dns_message(message, aa: false, rc: :dns_terms_const.dns_rcode_servfail)
      end
    else
      message = ExDNS.Resolver.resolve(message, authority, host)
      maybe_cache_packet(message, ExDNS.Records.dns_message(message, :aa))
    end
  end

  defp maybe_cache_packet(message, true) do
    ExDNS.PacketCache.put(ExDNS.Records.dns_message(message, :questions), message)
    message
  end

  defp maybe_cache_packet(message, false) do
    message
  end

  defp get_authority(message_or_name) do
    case ExDNS.Zone.Cache.get_authority(message_or_name) do
      {:ok, authority} -> [authority]
      {:error, _} -> []
    end
  end

  defp complete_response(message) do
    notify_empty_response(ExDNS.Records.dns_message(message,
      anc: length(ExDNS.Records.dns_message(message, :answers)),
      auc: length(ExDNS.Records.dns_message(message, :authority)),
      adc: length(ExDNS.Records.dns_message(message, :additional)),
      qr: true
    ))
  end

  defp notify_empty_response(message) do
    rr_count = ExDNS.Records.dns_message(message, :anc) + ExDNS.Records.dns_message(message, :auc) + ExDNS.Records.dns_message(message, :adc)

    dns_rcode_refused = :dns_terms_const.dns_rcode_refused()
    case {ExDNS.Records.dns_message(message, :rc), rr_count} do
      {^dns_rcode_refused, _} ->
        ExDNS.Events.notify({:refused_response, ExDNS.Records.dns_message(message, :questions)})
        message
      {_, 0} ->
        ExDNS.Events.notify({:empty_response, message})
        message
      _ ->
        message
    end
  end
end
