defmodule Exdns.Zone.ParserTest do
  use ExUnit.Case, async: true
  require Exdns.Records

  # Zone translation

  test "json to zone with no SHA" do
    name = "example.com"
    soa_record = %{"name" => "example.com", "type" => "SOA", "ttl" => 3600, "data" => %{
        "mname" => "ns1.example.com", "rname" => "admin.example.com", "serial" => 1, "refresh" => 2, "retry" => 3, "expire" => 4, "minimum" => 5}}
    records = [soa_record]
    zone = Exdns.Zone.Parser.json_to_zone(%{"name" => name, "records" => records})
    assert zone.name == name
    assert zone.version == ""
    assert zone.authority == Exdns.Zone.Parser.json_record_to_rr(soa_record)
    assert zone.records == Enum.map(records, &Exdns.Zone.Parser.json_record_to_rr/1)
    assert zone.records_by_name == %{name => Enum.map(records, &Exdns.Zone.Parser.json_record_to_rr/1)}
  end

  test "json to zone with SHA" do
    name = "example.com"; sha = "sha"
    soa_record = %{"name" => "example.com", "type" => "SOA", "ttl" => 3600, "data" => %{
        "mname" => "ns1.example.com", "rname" => "admin.example.com", "serial" => 1, "refresh" => 2, "retry" => 3, "expire" => 4, "minimum" => 5}}
    records = [soa_record]
    zone = Exdns.Zone.Parser.json_to_zone(%{"name" => name, "sha" => sha, "records" => records})
    assert zone.name == name
    assert zone.version == sha
    assert zone.authority == Exdns.Zone.Parser.json_record_to_rr(soa_record)
    assert zone.records == Enum.map(records, &Exdns.Zone.Parser.json_record_to_rr/1)
    assert zone.records_by_name == %{name => Enum.map(records, &Exdns.Zone.Parser.json_record_to_rr/1)}
  end

  # Context

  test "apply context options with no context" do
    assert Exdns.Zone.Parser.apply_context_options(%{}) == :pass
  end

  # Record translation

  test "json record to A RR" do
    name = "example.com"; ttl = 3600
    data = %{"ip" => "1.2.3.4"}
    rr = Exdns.Zone.Parser.json_record_to_rr(%{"name" => name, "type" => "A", "ttl" => ttl, "data" => data})
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_a(:ip)) == {1,2,3,4}
  end

  test "json record to AAAA RR" do
    name = "example.com"; ttl = 3600
    data = %{"ip" => "::1"}
    rr = Exdns.Zone.Parser.json_record_to_rr(%{"name" => name, "type" => "AAAA", "ttl" => ttl, "data" => data})
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_aaaa(:ip)) == {0,0,0,0,0,0,0,1}
  end

  test "json record to CNAME RR" do
    name = "example.com"; ttl = 3600
    data = %{"dname" => "somesite.com"}
    rr = Exdns.Zone.Parser.json_record_to_rr(%{"name" => name, "type" => "CNAME", "ttl" => ttl, "data" => data})
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_cname(:dname)) == "somesite.com"
  end

  test "json record to HINFO RR" do
    name = "example.com"; ttl = 3600
    data = %{"cpu" => "i386", "os" => "linux"}
    rr = Exdns.Zone.Parser.json_record_to_rr(%{"name" => name, "type" => "HINFO", "ttl" => ttl, "data" => data})
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_hinfo(:cpu)) == "i386"
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_hinfo(:os)) == "linux"
  end

  test "json record to MX RR" do
    name = "example.com"; ttl = 3600
    data = %{"exchange" => "mx1.mail.com", "preference" => "20"}
    rr = Exdns.Zone.Parser.json_record_to_rr(%{"name" => name, "type" => "MX", "ttl" => ttl, "data" => data})
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_mx(:exchange)) == "mx1.mail.com"
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_mx(:preference)) == "20"
  end

  test "json record to NAPTR RR" do
    name = "example.com"; ttl = 3600
    data = %{"order" => "1", "preference" => "20", "flags" => "u", "services" => "tcp", "regexp" => "", "replacement" => ""}
    rr = Exdns.Zone.Parser.json_record_to_rr(%{"name" => name, "type" => "NAPTR", "ttl" => ttl, "data" => data})
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_naptr(:order)) == "1"
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_naptr(:preference)) == "20"
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_naptr(:flags)) == "u"
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_naptr(:services)) == "tcp"
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_naptr(:regexp)) == ""
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_naptr(:replacement)) == ""
  end

  test "json record to NS RR" do
    name = "example.com"; ttl = 3600
    data = %{"dname" => "ns1.example.com"}
    rr = Exdns.Zone.Parser.json_record_to_rr(%{"name" => name, "type" => "NS", "ttl" => ttl, "data" => data})
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_ns(:dname)) == "ns1.example.com"
  end

  test "json record to RP RR" do
    name = "example.com"; ttl = 3600
    data = %{"mbox" => "hostmaster.example.com", "txt" => "rp.example.com"}
    rr = Exdns.Zone.Parser.json_record_to_rr(%{"name" => name, "type" => "RP", "ttl" => ttl, "data" => data})
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_rp(:mbox)) == "hostmaster.example.com"
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_rp(:txt)) == "rp.example.com"
  end

  test "json record to SOA RR" do
    name = "example.com"; ttl = 3600
    data = %{"mname" => "ns1.example.com", "rname" => "admin.example.com", "serial" => 1, "refresh" => 2, "retry" => 3, "expire" => 4, "minimum" => 5}
    rr = Exdns.Zone.Parser.json_record_to_rr(%{"name" => name, "type" => "SOA", "ttl" => ttl, "data" => data})
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_soa(:mname)) == "ns1.example.com"
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_soa(:rname)) == "admin.example.com"
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_soa(:serial)) == 1
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_soa(:refresh)) == 2
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_soa(:retry)) == 3
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_soa(:expire)) == 4
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_soa(:minimum)) == 5
  end

  test "json record to SPF RR" do
    name = "example.com"; ttl = 3600
    data = %{"spf" => "v=spf1 -all"}
    rr = Exdns.Zone.Parser.json_record_to_rr(%{"name" => name, "type" => "SPF", "ttl" => ttl, "data" => data})
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_spf(:spf)) == "v=spf1 -all"
  end

  test "json record to SRV RR" do
    name = "example.com"; ttl = 3600
    data = %{"priority" => "10", "weight" => "20", "port" => "5050", "target" => "x.example.com"}
    rr = Exdns.Zone.Parser.json_record_to_rr(%{"name" => name, "type" => "SRV", "ttl" => ttl, "data" => data})
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_srv(:priority)) == "10"
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_srv(:weight)) == "20"
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_srv(:port)) == "5050"
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_srv(:target)) == "x.example.com"
  end

  test "json record to SSHFP RR" do
    name = "example.com"; ttl = 3600
    data = %{"alg" => "2", "fp_type" => "1", "fp" => "123456789abcdef67890123456789abcdef67890"}
    rr = Exdns.Zone.Parser.json_record_to_rr(%{"name" => name, "type" => "SSHFP", "ttl" => ttl, "data" => data})
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_sshfp(:alg)) == "2"
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_sshfp(:fp_type)) == "1"
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_sshfp(:fp)) == <<18, 52, 86, 120, 154, 188, 222, 246, 120, 144, 18, 52, 86, 120, 154, 188, 222, 246, 120, 144>>
  end

  test "json record to TXT RR" do
    name = "example.com"; ttl = 3600
    data = %{"txt" => "this is some text"}
    rr = Exdns.Zone.Parser.json_record_to_rr(%{"name" => name, "type" => "TXT", "ttl" => ttl, "data" => data})
    assert (Exdns.Records.dns_rr(rr, :data) |> Exdns.Records.dns_rrdata_txt(:txt)) == ["this is some text"]
  end

  # Named index

  test "build empty named index" do
    index = Exdns.Zone.Parser.build_named_index([])
    assert Map.keys(index) == []
  end
  test "build named index" do
    name = "example.com"; ttl = 3600
    data = %{"mname" => "ns1.example.com", "rname" => "admin.example.com", "serial" => 1, "refresh" => 2, "retry" => 3, "expire" => 4, "minimum" => 5}
    rr = Exdns.Zone.Parser.json_record_to_rr(%{"name" => name, "type" => "SOA", "ttl" => ttl, "data" => data})
    index = Exdns.Zone.Parser.build_named_index([rr])
    assert index[name] != nil
  end

end
