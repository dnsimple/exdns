defmodule Exdns.ResolverTest do
  require Logger
  require Exdns.Records

  use ExUnit.Case, async: true

  test "resolve with no questions" do
    message = Exdns.Records.dns_message()
    assert Exdns.Resolver.resolve(message, :authority, :host) == message
  end

  test "resolve with one question for type A" do
    {:ok, zone} = Exdns.ZoneCache.get_zone("example.com")
    assert zone.authority != :undefined
    question = Exdns.Records.dns_query(name: "outpost.example.com", type: :dns_terms_const.dns_type_a)
    message = Exdns.Records.dns_message(questions: [question])
    answer = Exdns.Resolver.resolve(message, [zone.authority], :host)
    assert length(Exdns.Records.dns_message(answer, :answers)) > 0
  end

  test "resolve with one question for type CNAME" do
    {:ok, zone} = Exdns.ZoneCache.get_zone("example.com")
    assert zone.authority != :undefined
    question = Exdns.Records.dns_query(name: "www.example.com", type: :dns_terms_const.dns_type_cname)
    message = Exdns.Records.dns_message(questions: [question])
    answer = Exdns.Resolver.resolve(message, [zone.authority], :host)
    assert length(Exdns.Records.dns_message(answer, :answers)) > 0
  end

  test "resolve with one question for type SOA" do
    {:ok, zone} = Exdns.ZoneCache.get_zone("example.com")
    assert zone.authority != :undefined
    question = Exdns.Records.dns_query(name: "example.com", type: :dns_terms_const.dns_type_soa)
    message = Exdns.Records.dns_message(questions: [question])
    answer = Exdns.Resolver.resolve(message, [zone.authority], :host)
    assert length(Exdns.Records.dns_message(answer, :answers)) > 0
  end

  # Step 3 tests
  test "test resolve when not authoritative" do
    question = Exdns.Records.dns_query(name: "notfound.com", type: :dns_terms_const.dns_type_a)
    message = Exdns.Records.dns_message(questions: [question])
    answer = Exdns.Resolver.resolve(message, [], :host)
    assert Exdns.Records.dns_message(answer, :aa)
    assert Exdns.Records.dns_message(answer, :rc) == :dns_terms_const.dns_rcode_noerror
    assert length(Exdns.Records.dns_message(answer, :answers)) == 0
    assert length(Exdns.Records.dns_message(answer, :authority)) == 0
    assert length(Exdns.Records.dns_message(answer, :additional)) == 0
  end

  test "test resolve when not authoritative and returning root hints" do
    Application.put_env(:exdns, :use_root_hints, true)
    question = Exdns.Records.dns_query(name: "notfound.com", type: :dns_terms_const.dns_type_a)
    message = Exdns.Records.dns_message(questions: [question])
    answer = Exdns.Resolver.resolve(message, [], :host)
    assert Exdns.Records.dns_message(answer, :aa)
    assert Exdns.Records.dns_message(answer, :rc) == :dns_terms_const.dns_rcode_noerror
    assert length(Exdns.Records.dns_message(answer, :answers)) == 0
    assert length(Exdns.Records.dns_message(answer, :authority)) > 0
    assert length(Exdns.Records.dns_message(answer, :additional)) > 0
    Application.put_env(:exdns, :use_root_hints, false)
  end

  test "test any wildcard" do
    {:ok, zone} = Exdns.ZoneCache.get_zone("wtest.com")
    assert zone.authority != :undefined
    question = Exdns.Records.dns_query(name: "fwejfiwerrfj.something.wtest.com", type: :dns_terms_const.dns_type_a)
    message = Exdns.Records.dns_message(questions: [question])
    answer = Exdns.Resolver.resolve(message, zone.authority, :host)
    assert Exdns.Records.dns_message(answer, :aa)
    assert length(Exdns.Records.dns_message(answer, :answers)) > 0
    assert length(Exdns.Records.dns_message(answer, :authority)) == 0
    assert length(Exdns.Records.dns_message(answer, :additional)) == 0
  end

  test "cname and wildcard at root" do
    {:ok, zone} = Exdns.ZoneCache.get_zone("wtest.com")
    assert zone.authority != :undefined
    question = Exdns.Records.dns_query(name: "secure.wtest.com", type: :dns_terms_const.dns_type_a)
    message = Exdns.Records.dns_message(questions: [question])
    answer = Exdns.Resolver.resolve(message, zone.authority, :host)
    assert Exdns.Records.dns_message(answer, :aa)
    assert length(Exdns.Records.dns_message(answer, :answers)) == 0
    assert length(Exdns.Records.dns_message(answer, :authority)) > 0
    assert length(Exdns.Records.dns_message(answer, :additional)) == 0
  end

  test "cname and wildcard but no correct type" do
    {:ok, zone} = Exdns.ZoneCache.get_zone("test.com")
    assert zone.authority != :undefined
    question = Exdns.Records.dns_query(name: "yo.test.test.com", type: :dns_terms_const.dns_type_aaaa)
    message = Exdns.Records.dns_message(questions: [question])
    answer = Exdns.Resolver.resolve(message, zone.authority, :host)
    assert Exdns.Records.dns_message(answer, :aa)
    assert length(Exdns.Records.dns_message(answer, :answers)) > 0
    assert length(Exdns.Records.dns_message(answer, :authority)) > 0
    assert length(Exdns.Records.dns_message(answer, :additional)) == 0
  end


  test "parent?" do
    assert Exdns.Resolver.parent?("example.com", "example.com")
  end


  test "type matched records" do
    soa_rr = Exdns.Records.dns_rr(type: :dns_terms_const.dns_type_soa)
    a_rr = Exdns.Records.dns_rr(type: :dns_terms_const.dns_type_a)
    records = [soa_rr, a_rr]
    assert Exdns.Resolver.type_match_records(records, :dns_terms_const.dns_type_soa) == [soa_rr]
    assert Exdns.Resolver.type_match_records(records, :dns_terms_const.dns_type_any) == [soa_rr, a_rr]
    assert Exdns.Resolver.type_match_records(records, :dns_terms_const.dns_type_cname) == []
  end


  test "filter records" do
    # TBD
  end


  test "rewrite SOA ttl" do
    soa_rrdata = Exdns.Records.dns_rrdata_soa(minimum: 60)
    soa_rr = Exdns.Records.dns_rr(name: "example.com", type: :dns_terms_const.dns_type_soa, ttl: 3600, data: soa_rrdata)
    message = Exdns.Records.dns_message(authority: [soa_rr])
    assert Exdns.Resolver.rewrite_soa_ttl(message) |> Exdns.Records.dns_message(:authority) |> List.last |> Exdns.Records.dns_rr(:ttl) == 60
  end


  test "additional processing" do
    # TBD
  end

  test "requires additional processing with no answers returns the names that are being checked" do
    assert Exdns.Resolver.requires_additional_processing([], [:name]) == [:name]
  end


  test "check_dnssec" do
    assert Exdns.Resolver.check_dnssec(:message, :host, :question) == false
  end

end
