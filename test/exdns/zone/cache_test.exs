defmodule ExDNS.Zone.CacheTest do
  use ExUnit.Case, async: false
  require ExDNS.Records

  setup do
    name = "example.com"

    soa_record = ExDNS.Records.dns_rr(name: name, type: :dns_terms_const.dns_type_soa, data: ExDNS.Records.dns_rrdata_soa())
    ns_record = ExDNS.Records.dns_rr(name: name, type: :dns_terms_const.dns_type_ns, data: ExDNS.Records.dns_rrdata_ns(dname: "ns1.example.com"))
    cname_record = ExDNS.Records.dns_rr(name: "www.#{name}", type: :dns_terms_const.dns_type_cname, data: ExDNS.Records.dns_rrdata_cname(dname: "something.com"))

    records = [soa_record, ns_record, cname_record]
    zone = %ExDNS.Zone{name: name, authority: soa_record, records: records, records_by_name: ExDNS.Zone.Parser.build_named_index(records)}

    ExDNS.Zone.Cache.put_zone(name, zone)

    {:ok, %{:zone => zone, delegation: ns_record, authority: soa_record, cname_record: cname_record}}
  end

  test "find zone not found" do
    assert ExDNS.Zone.Cache.find_zone("notfound.com") == {:error, :not_authoritative}
  end

  test "find zone", %{zone: zone} do
    assert ExDNS.Zone.Cache.find_zone(zone.name) == %{zone | records: [], records_by_name: :trimmed}
  end

  test "get zone", %{zone: zone} do
    assert ExDNS.Zone.Cache.get_zone(zone.name) == {:ok, %{zone | records: [], records_by_name: :trimmed}}
  end

  test "get authority for name", %{zone: zone} do
    {:ok,authority} = ExDNS.Zone.Cache.get_authority(zone.name)
    assert ExDNS.Records.dns_rr(authority, :type) == :dns_terms_const.dns_type_soa
  end

  test "get authority for message", %{zone: zone} do
    question = ExDNS.Records.dns_query(name: zone.name, type: :dns_terms_const.dns_type_a)
    message = ExDNS.Records.dns_message(questions: [question])
    {:ok, authority} = ExDNS.Zone.Cache.get_authority(message)
    assert ExDNS.Records.dns_rr(authority, :type) == :dns_terms_const.dns_type_soa
  end


  test "get records by name", %{zone: zone, cname_record: cname_record} do
    assert ExDNS.Zone.Cache.get_records_by_name("example.com") == zone.records -- [cname_record]
    assert ExDNS.Zone.Cache.get_records_by_name("www.example.com") == [cname_record]
  end


  test "in_zone?" do
    assert ExDNS.Zone.Cache.in_zone?("example.com")
  end


  test "get delegations returns delegation records", %{delegation: ns_record} do
    assert ExDNS.Zone.Cache.get_delegations("example.com") == []
    assert ExDNS.Zone.Cache.get_delegations("ns1.example.com") == [ns_record]
  end


  test "find zone in cache exact name", %{zone: zone} do
    assert ExDNS.Zone.Cache.find_zone_in_cache("example.com") == {:ok, zone}
  end

  test "find zone in cache subdomain", %{zone: zone} do
    assert ExDNS.Zone.Cache.find_zone_in_cache("fewf.afdaf.example.com") == {:ok, zone}
  end

  test "find zone in cache not found" do
    assert ExDNS.Zone.Cache.find_zone_in_cache("notfound.com") == {:error, :zone_not_found}
  end

  test "normalize name" do
    assert ExDNS.Zone.Cache.normalize_name("eXaMpLe.CoM") == "example.com"
  end

  test "fallback to wildcard zone when configured" do
    Application.put_env(:ex_dns, :wildcard_fallback, true)
    {:ok, _zone} = ExDNS.Zone.Cache.find_zone_in_cache("notfound.com")
    Application.put_env(:ex_dns, :wildcard_fallback, false)
  end
end
