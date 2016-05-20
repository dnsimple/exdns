defmodule Exdns.ZoneParser do
  require Logger
  require Exdns.Records
 
  @doc """
  Convert a Map structure from exjxs to an Exdns.ZoneCache.Zone instance.

  The keys `name` and `records` are required.

  The `sha` key is optional. If the `sha` key is not present, the value is set to an empty string.
  """
  def json_to_zone(%{"name" => name, "sha" => sha, "records" => records}) do
    json_to_zone(name, sha, records)
  end
  def json_to_zone(%{"name" => name, "records" => records}) do
    json_to_zone(name, "", records)
  end

  defp json_to_zone(name, sha, records) do
    records = Enum.map(records, fn(r) ->
      # filter by context
      case apply_context_options(r) do
        :pass ->
          case json_record_to_rr(r) do
            {} -> try_custom_parsers(r, [])
            record -> record
          end
        _ ->
          {}
      end
    end)

    records_by_name = build_named_index(records)
    authorities = Enum.filter(records, Exdns.Records.match_type(:dns_terms_const.dns_type_soa))
    %Exdns.ZoneCache.Zone{
      name: name,
      version: sha,
      records: records,
      records_by_name: records_by_name,
      authority: List.last(authorities)
    }
  end

  def apply_context_options(record = %{"context" => context}) do
    case Application.get_env(:exdns, :context_options) do
      {:ok, context_options} ->
        context_set = Set.from_list(context)
        result = [] # TODO implement
        if Enum.any?(result, fn(i) -> i == :pass end) do
          :pass
        else
          :fail
        end
      _ ->
        :pass
    end
  end
  def apply_context_options(_), do: :pass

  def try_custom_parsers(record, parsers) do
    {}
  end

  @doc """
  Convert a Map structure from exjsx to a DNS resource record
  """
  def json_record_to_rr(%{"name" => name, "type" => "A", "ttl" => ttl, "data" => data}) do
    raw_ip = data["ip"]
    case :inet_parse.address(to_char_list(raw_ip)) do
      {:ok, address} -> Exdns.Records.dns_rr(name: name, type: :dns_terms_const.dns_type_a, data: Exdns.Records.dns_rrdata_a(ip: address), ttl: ttl)
      {:error, reason} -> Logger.error("Failed to parse A record address #{raw_ip}: #{reason}")
    end
   
  end

  def json_record_to_rr(%{"name" => name, "type" => "NS", "ttl" => ttl, "data" => data}) do
    rrdata = Exdns.Records.dns_rrdata_ns(dname: data["dname"])
    Exdns.Records.dns_rr(name: name, type: :dns_terms_const.dns_type_ns, data: rrdata, ttl: ttl)
  end

  def json_record_to_rr(%{"name" => name, "type" => "SOA", "ttl" => ttl, "data" => data}) do
    rrdata = Exdns.Records.dns_rrdata_soa(mname: data["mname"], rname: data["rname"],
      serial: data["serial"], refresh: data["refresh"], retry: data["retry"],
      expire: data["expire"], minimum: data["minimum"])
    Exdns.Records.dns_rr(name: name, type: :dns_terms_const.dns_type_soa, data: rrdata, ttl: ttl)
  end
  

  @doc """
  Builds an index for the given records, where each key is a unique name and 
  the contents is a list of records with that name.
  """
  def build_named_index(records) do
    build_named_index(records, %{})
  end

  defp build_named_index([], index), do: index
  defp build_named_index([r|rest], index) do
    name = Exdns.Records.dns_rr(r, :name)
    case Map.get(index, name) do
      nil -> build_named_index(rest, Map.put(index, Exdns.ZoneCache.normalize_name(name), [r]))
      records -> build_named_index(rest, Map.put(index, Exdns.ZoneCache.normalize_name(name), records ++ [r]))
    end
  end
end
