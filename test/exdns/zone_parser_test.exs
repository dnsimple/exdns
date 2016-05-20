defmodule Exdns.ZoneParserTest do
  require Exdns.Records

  use ExUnit.Case, async: true

  # Zone translation

  test "json to zone with no SHA" do
    name = "example.com"
    soa_record = %{"name" => "example.com", "type" => "SOA", "ttl" => 3600, "data" => %{
        "mname" => "ns1.example.com", "rname" => "admin.example.com", "serial" => 1, "refresh" => 2, "retry" => 3, "expire" => 4, "minimum" => 5}}
    records = [soa_record]
    zone = Exdns.ZoneParser.json_to_zone(%{"name" => name, "records" => records})
    assert zone.name == name
    assert zone.version == ""
    assert zone.authority == Exdns.ZoneParser.json_record_to_rr(soa_record)
    assert zone.records == Enum.map(records, &Exdns.ZoneParser.json_record_to_rr/1)
    assert zone.records_by_name == %{name => Enum.map(records, &Exdns.ZoneParser.json_record_to_rr/1)}
  end

  test "json to zone with SHA" do
    name = "example.com"; sha = "sha"
    soa_record = %{"name" => "example.com", "type" => "SOA", "ttl" => 3600, "data" => %{
        "mname" => "ns1.example.com", "rname" => "admin.example.com", "serial" => 1, "refresh" => 2, "retry" => 3, "expire" => 4, "minimum" => 5}}
    records = [soa_record]
    zone = Exdns.ZoneParser.json_to_zone(%{"name" => name, "sha" => sha, "records" => records})
    assert zone.name == name
    assert zone.version == sha
    assert zone.authority == Exdns.ZoneParser.json_record_to_rr(soa_record)
    assert zone.records == Enum.map(records, &Exdns.ZoneParser.json_record_to_rr/1)
    assert zone.records_by_name == %{name => Enum.map(records, &Exdns.ZoneParser.json_record_to_rr/1)}
  end

  # Context

  test "apply context options with no context" do
    assert Exdns.ZoneParser.apply_context_options(%{}) == :pass
  end

  # Record translation

  test "json record to SOA RR" do
    name = "example.com"; ttl = 3600
    data = %{"mname" => "ns1.example.com", "rname" => "admin.example.com", "serial" => 1, "refresh" => 2, "retry" => 3, "expire" => 4, "minimum" => 5}
    rr = Exdns.ZoneParser.json_record_to_rr(%{"name" => name, "type" => "SOA", "ttl" => ttl, "data" => data})
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_soa(:mname)) == "ns1.example.com"
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_soa(:rname)) == "admin.example.com"
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_soa(:serial)) == 1
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_soa(:refresh)) == 2
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_soa(:retry)) == 3
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_soa(:expire)) == 4
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_soa(:minimum)) == 5
  end

  test "json record to NS RR" do
    name = "example.com"; ttl = 3600
    data = %{"dname" => "ns1.example.com"}
    rr = Exdns.ZoneParser.json_record_to_rr(%{"name" => name, "type" => "NS", "ttl" => ttl, "data" => data})
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_ns(:dname)) == "ns1.example.com"
  end

  # Named index

  test "build empty named index" do
    index = Exdns.ZoneParser.build_named_index([])
    assert Map.keys(index) == []
  end
  test "build named index" do
    name = "example.com"; ttl = 3600
    data = %{"mname" => "ns1.example.com", "rname" => "admin.example.com", "serial" => 1, "refresh" => 2, "retry" => 3, "expire" => 4, "minimum" => 5}
    rr = Exdns.ZoneParser.json_record_to_rr(%{"name" => name, "type" => "SOA", "ttl" => ttl, "data" => data})
    index = Exdns.ZoneParser.build_named_index([rr])
    assert index[name] != nil
  end

end
