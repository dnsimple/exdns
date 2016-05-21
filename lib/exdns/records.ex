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

  def root_hints() do
    {
      [
        dns_rr(name: "", type: :dns_terms_const.dns_type_ns, ttl: 518400, data: dns_rrdata_ns(dname: "a.root-servers.net")),
        dns_rr(name: "", type: :dns_terms_const.dns_type_ns, ttl: 518400, data: dns_rrdata_ns(dname: "b.root-servers.net")),
        dns_rr(name: "", type: :dns_terms_const.dns_type_ns, ttl: 518400, data: dns_rrdata_ns(dname: "c.root-servers.net")),
        dns_rr(name: "", type: :dns_terms_const.dns_type_ns, ttl: 518400, data: dns_rrdata_ns(dname: "d.root-servers.net")),
        dns_rr(name: "", type: :dns_terms_const.dns_type_ns, ttl: 518400, data: dns_rrdata_ns(dname: "e.root-servers.net")),
        dns_rr(name: "", type: :dns_terms_const.dns_type_ns, ttl: 518400, data: dns_rrdata_ns(dname: "f.root-servers.net")),
        dns_rr(name: "", type: :dns_terms_const.dns_type_ns, ttl: 518400, data: dns_rrdata_ns(dname: "g.root-servers.net")),
        dns_rr(name: "", type: :dns_terms_const.dns_type_ns, ttl: 518400, data: dns_rrdata_ns(dname: "h.root-servers.net")),
        dns_rr(name: "", type: :dns_terms_const.dns_type_ns, ttl: 518400, data: dns_rrdata_ns(dname: "i.root-servers.net")),
        dns_rr(name: "", type: :dns_terms_const.dns_type_ns, ttl: 518400, data: dns_rrdata_ns(dname: "j.root-servers.net")),
        dns_rr(name: "", type: :dns_terms_const.dns_type_ns, ttl: 518400, data: dns_rrdata_ns(dname: "k.root-servers.net")),
        dns_rr(name: "", type: :dns_terms_const.dns_type_ns, ttl: 518400, data: dns_rrdata_ns(dname: "l.root-servers.net")),
        dns_rr(name: "", type: :dns_terms_const.dns_type_ns, ttl: 518400, data: dns_rrdata_ns(dname: "m.root-servers.net"))
      ],
      [
        dns_rr(name: "a.root-servers.net", type: :dns_terms_const.dns_type_a, ttl: 3600000, data: dns_rrdata_a(ip: {198,41,0,4})),
        dns_rr(name: "b.root-servers.net", type: :dns_terms_const.dns_type_a, ttl: 3600000, data: dns_rrdata_a(ip: {192,228,79,201})),
        dns_rr(name: "c.root-servers.net", type: :dns_terms_const.dns_type_a, ttl: 3600000, data: dns_rrdata_a(ip: {192,33,4,12})),
        dns_rr(name: "d.root-servers.net", type: :dns_terms_const.dns_type_a, ttl: 3600000, data: dns_rrdata_a(ip: {128,8,10,90})),
        dns_rr(name: "e.root-servers.net", type: :dns_terms_const.dns_type_a, ttl: 3600000, data: dns_rrdata_a(ip: {192,203,230,10})),
        dns_rr(name: "f.root-servers.net", type: :dns_terms_const.dns_type_a, ttl: 3600000, data: dns_rrdata_a(ip: {192,5,5,241})),
        dns_rr(name: "g.root-servers.net", type: :dns_terms_const.dns_type_a, ttl: 3600000, data: dns_rrdata_a(ip: {192,112,36,4})),
        dns_rr(name: "h.root-servers.net", type: :dns_terms_const.dns_type_a, ttl: 3600000, data: dns_rrdata_a(ip: {128,63,2,53})),
        dns_rr(name: "i.root-servers.net", type: :dns_terms_const.dns_type_a, ttl: 3600000, data: dns_rrdata_a(ip: {192,36,148,17})),
        dns_rr(name: "j.root-servers.net", type: :dns_terms_const.dns_type_a, ttl: 3600000, data: dns_rrdata_a(ip: {192,58,128,30})),
        dns_rr(name: "k.root-servers.net", type: :dns_terms_const.dns_type_a, ttl: 3600000, data: dns_rrdata_a(ip: {193,0,14,129})),
        dns_rr(name: "l.root-servers.net", type: :dns_terms_const.dns_type_a, ttl: 3600000, data: dns_rrdata_a(ip: {198,32,64,12})),
        dns_rr(name: "m.root-servers.net", type: :dns_terms_const.dns_type_a, ttl: 3600000, data: dns_rrdata_a(ip: {202,12,27,33}))
      ]
    }
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
