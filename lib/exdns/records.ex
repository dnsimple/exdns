# Imports all of the records from dns_erlang/include/dns_records.hrl

defmodule Exdns.Records do
  require Record

  # Records brought in from dns_erlang

  Record.defrecord(:dns_message, Record.extract(:dns_message, from_lib: "dns_erlang/include/dns_records.hrl"))
  Record.defrecord(:dns_query, Record.extract(:dns_query, from_lib: "dns_erlang/include/dns_records.hrl"))
  Record.defrecord(:dns_rr, Record.extract(:dns_rr, from_lib: "dns_erlang/include/dns_records.hrl"))
  Record.defrecord(:dns_rrdata_a, Record.extract(:dns_rrdata_a, from_lib: "dns_erlang/include/dns_records.hrl"))
  Record.defrecord(:dns_rrdata_cname, Record.extract(:dns_rrdata_cname, from_lib: "dns_erlang/include/dns_records.hrl"))
  Record.defrecord(:dns_rrdata_ns, Record.extract(:dns_rrdata_ns, from_lib: "dns_erlang/include/dns_records.hrl"))
  Record.defrecord(:dns_rrdata_soa, Record.extract(:dns_rrdata_soa, from_lib: "dns_erlang/include/dns_records.hrl"))


  # Utility functions

  def minimum_soa_ttl(record, data) do
    case record do
      _ when Record.is_record(data, :dns_rrdata_soa) ->
        dns_rr(record, ttl: min(dns_rrdata_soa(data, :minimum), dns_rr(record, :ttl)))
      _ -> record
    end
  end

  # Matchers

  def match_name(name) do
    fn(r) ->
      case r do
        ^r when Record.is_record(r, :dns_rr) -> dns_rr(r, :name) == name
        _ -> false
      end
    end
  end

  def match_type(type) do
    fn(r) ->
      case r do
        ^r when Record.is_record(r, :dns_rr) -> dns_rr(r, :type) == type
        _ -> false
      end
    end
  end

  def match_name_and_type(name, type) do
    fn(r) ->
      case r do
        ^r when Record.is_record(r, :dns_rr) -> dns_rr(r, :type) == type && dns_rr(r, :name) == name
        _ -> false
      end
    end
  end

  def match_types(types) do
    fn(r) ->
      case r do
        ^r when Record.is_record(r, :dns_rr) -> Enum.any?(types, fn(t) -> dns_rr(r, :type) == t end)
        _ -> false
      end
    end
  end

  def match_wildcard() do
    fn(r) ->
      case r do
        ^r when Record.is_record(r, :dns_rr) -> Enum.any?(:dns.dname_to_labels(dns_rr(r, :name)), match_wildcard_label())
        _ -> false
      end
    end
  end

  def match_delegation(name) do
    fn(r) ->
      dns_rr(r, :data) == dns_rrdata_ns(dname: name)
    end
  end

  defp match_wildcard_label() do
    fn(l) ->
      l == "*"
    end
  end

end
