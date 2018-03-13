defmodule ExDNS.Zone.Cache do
  @moduledoc """
  In-memory cache for all zones.
  """

  use GenServer
  require ExDNS.Records

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: ExDNS.Zone.Cache)
  end

  def find_zone(qname) do
    find_zone(normalize_name(qname), get_authority(qname))
  end

  def find_zone(qname, {:error, _}) do
    find_zone(qname, [])
  end
  def find_zone(qname, {:ok, authority}) do
    find_zone(qname, authority)
  end
  def find_zone(_qname, []) do
    {:error, :not_authoritative}
  end
  def find_zone(qname, authorities) when is_list(authorities) do
    find_zone(qname, List.last(authorities))
  end
  def find_zone(name, authority) do
    name = normalize_name(name)
    case :dns.dname_to_labels(name) do
      [] -> {:error, :zone_not_found}
      [_|labels] ->
        case get_zone(name) do
          {:ok, zone} -> zone
          {:error, :zone_not_found} ->
            if name == ExDNS.Records.dns_rr(authority, :name) do
              {:error, :zone_not_found}
            else
              find_zone(:dns.labels_to_dname(labels), authority)
            end
        end
    end
  end

  def get_zone(name) do
    name = normalize_name(name)
    case ExDNS.Storage.select(:zones, name) do
      [{^name, zone}] -> {:ok, %{zone | records: [], records_by_name: :trimmed}}
      _ -> get_fallback()
    end
  end

  defp get_fallback do
    case get_wildcard_zone() do
      {:ok, zone} -> {:ok, %{zone | records: [], records_by_name: :trimmed}}
      _ -> {:error, :zone_not_found}
    end
  end

  defp get_wildcard_zone do
    if ExDNS.Config.wildcard_fallback? do
      case ExDNS.Storage.select(:zones, "*") do
        [{"*", zone}] -> {:ok, zone}
        _ -> {:error, :zone_not_found}
      end
    else
      {:error, :zone_not_found}
    end
  end

  def get_authority(name) when is_binary(name) do
    case find_zone_in_cache(normalize_name(name)) do
      {:ok, zone} -> {:ok, zone.authority}
      _ -> {:error, :authority_not_found}
    end
  end
  def get_authority(message) do
    case ExDNS.Records.dns_message(message, :questions) do
      [] -> {:error, :no_question}
      questions -> List.last(questions) |> ExDNS.Records.dns_query(:name) |> get_authority()
    end
  end


  def get_delegations(name) do
    case find_zone_in_cache(name) do
      {:ok, zone} ->
        Enum.filter(zone.records, fn(r) -> apply(ExDNS.Records.match_type(:dns_terms_const.dns_type_ns), [r]) and apply(ExDNS.Records.match_delegation(name), [r]) end)
      _ ->
        []
    end
  end


  def get_records_by_name(name) do
    case find_zone_in_cache(name) do
      {:ok, zone} -> Map.get(zone.records_by_name, normalize_name(name), [])
      _ -> []
    end
  end


  def in_zone?(name) do
    case find_zone_in_cache(name) do
      {:ok, zone} -> is_name_in_zone(name, zone)
      _ -> false
    end
  end


  def put_zone(name, zone) do
    ExDNS.Storage.insert(:zones, {normalize_name(name), zone})
    :ok
  end

  # GenServer callbacks

  def init([]) do
    ExDNS.Storage.create(:schema)
    ExDNS.Storage.create(:zones)
    ExDNS.Storage.create(:authorities)
    {:ok, %{:parsers => []}}
  end

  # Internal API

  def is_name_in_zone(name, zone) do
    if Map.has_key?(zone.records_by_name, normalize_name(name)) do
      true
    else
      case :dns.dname_to_labels(name) do
        [] -> false
        [_] -> false
        [_|labels] -> is_name_in_zone(:dns.labels_to_dname(labels), zone)
      end
    end
  end

  def find_zone_in_cache(name) do
    find_zone_in_cache(normalize_name(name), :dns.dname_to_labels(name))
  end
  def find_zone_in_cache(_name, []) do
    get_wildcard_zone()
  end
  def find_zone_in_cache(name, [_|labels]) do
    case ExDNS.Storage.select(:zones, name) do
      [{_name, zone}] -> {:ok, zone}
      _ ->
        case labels do
          [] -> get_wildcard_zone()
          _ -> find_zone_in_cache(:dns.labels_to_dname(labels), labels)
        end
    end
  end

  def normalize_name(name), do: String.downcase(name)
end
