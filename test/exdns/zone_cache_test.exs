defmodule Exdns.ZoneCacheTest do
  require Exdns.Records

  use ExUnit.Case, async: false

  setup do
    name = "example.com"

    soa_record = Exdns.Records.dns_rr(name: name, type: :dns_terms_const.dns_type_soa, data: Exdns.Records.dns_rrdata_soa())
    ns_record = Exdns.Records.dns_rr(name: name, type: :dns_terms_const.dns_type_ns, data: Exdns.Records.dns_rrdata_ns(dname: "ns1.example.com"))
    cname_record = Exdns.Records.dns_rr(name: "www.#{name}", type: :dns_terms_const.dns_type_cname, data: Exdns.Records.dns_rrdata_cname(dname: "something.com"))

    records = [soa_record, ns_record, cname_record]
    zone = %Exdns.ZoneCache.Zone{name: name, authority: soa_record, records: records, records_by_name: Exdns.ZoneParser.build_named_index(records)}

    Exdns.ZoneCache.put_zone(name, zone)

    {:ok, %{:zone => zone, delegation: ns_record, authority: soa_record, cname_record: cname_record}}
  end

  test "find zone not found" do
    assert Exdns.ZoneCache.find_zone("notfound.com") == {:error, :not_authoritative}
  end

  test "find zone", %{zone: zone} do
    assert Exdns.ZoneCache.find_zone(zone.name) == %{zone | records: [], records_by_name: :trimmed}
  end

  test "get zone", %{zone: zone} do
    assert Exdns.ZoneCache.get_zone(zone.name) == {:ok, %{zone | records: [], records_by_name: :trimmed}}
  end

  test "get authority for name", %{zone: zone} do
    {:ok,authority} = Exdns.ZoneCache.get_authority(zone.name)
    assert Exdns.Records.dns_rr(authority, :type) == :dns_terms_const.dns_type_soa
  end

  test "get authority for message", %{zone: zone} do
    question = Exdns.Records.dns_query(name: zone.name, type: :dns_terms_const.dns_type_a)
    message = Exdns.Records.dns_message(questions: [question])
    {:ok, authority} = Exdns.ZoneCache.get_authority(message)
    assert Exdns.Records.dns_rr(authority, :type) == :dns_terms_const.dns_type_soa
  end


  test "get records by name", %{zone: zone, cname_record: cname_record} do
    assert Exdns.ZoneCache.get_records_by_name("example.com") == zone.records -- [cname_record]
    assert Exdns.ZoneCache.get_records_by_name("www.example.com") == [cname_record]
  end


  test "in_zone?" do
    assert Exdns.ZoneCache.in_zone?("example.com")
  end


  test "get delegations returns delegation records", %{delegation: ns_record} do
    assert Exdns.ZoneCache.get_delegations("example.com") == []
    assert Exdns.ZoneCache.get_delegations("ns1.example.com") == [ns_record]
  end


  test "find zone in cache exact name", %{zone: zone} do
    assert Exdns.ZoneCache.find_zone_in_cache("example.com") == {:ok, zone}
  end

  test "find zone in cache subdomain", %{zone: zone} do
    assert Exdns.ZoneCache.find_zone_in_cache("fewf.afdaf.example.com") == {:ok, zone}
  end

  test "find zone in cache not found" do
    assert Exdns.ZoneCache.find_zone_in_cache("notfound.com") == {:error, :zone_not_found}
  end


  test "normalize name" do
    assert Exdns.ZoneCache.normalize_name("eXaMpLe.CoM") == "example.com"
  end
end
