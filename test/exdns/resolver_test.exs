defmodule ExDNS.ResolverTest do
  use ExUnit.Case, async: true
  require Logger
  require ExDNS.Records

  test "resolve with no questions" do
    message = ExDNS.Records.dns_message()
    assert ExDNS.Resolver.resolve(message, :authority, :host) == message
  end

  test "resolve with one question for type A" do
    {:ok, zone} = ExDNS.Zone.Cache.get_zone("example.com")
    assert zone.authority != :undefined
    question = ExDNS.Records.dns_query(name: "outpost.example.com", type: :dns_terms_const.dns_type_a)
    message = ExDNS.Records.dns_message(questions: [question])
    answer = ExDNS.Resolver.resolve(message, [zone.authority], :host)
    assert length(ExDNS.Records.dns_message(answer, :answers)) > 0
  end

  test "resolve with one question for type CNAME" do
    {:ok, zone} = ExDNS.Zone.Cache.get_zone("example.com")
    assert zone.authority != :undefined
    question = ExDNS.Records.dns_query(name: "www.example.com", type: :dns_terms_const.dns_type_cname)
    message = ExDNS.Records.dns_message(questions: [question])
    answer = ExDNS.Resolver.resolve(message, [zone.authority], :host)
    assert length(ExDNS.Records.dns_message(answer, :answers)) > 0
  end

  test "resolve with one question for type SOA" do
    {:ok, zone} = ExDNS.Zone.Cache.get_zone("example.com")
    assert zone.authority != :undefined
    question = ExDNS.Records.dns_query(name: "example.com", type: :dns_terms_const.dns_type_soa)
    message = ExDNS.Records.dns_message(questions: [question])
    answer = ExDNS.Resolver.resolve(message, [zone.authority], :host)
    assert length(ExDNS.Records.dns_message(answer, :answers)) > 0
  end

  # Step 3 tests
  test "test resolve when not authoritative" do
    question = ExDNS.Records.dns_query(name: "notfound.com", type: :dns_terms_const.dns_type_a)
    message = ExDNS.Records.dns_message(questions: [question])
    answer = ExDNS.Resolver.resolve(message, [], :host)
    assert ExDNS.Records.dns_message(answer, :aa)
    assert ExDNS.Records.dns_message(answer, :rc) == :dns_terms_const.dns_rcode_noerror
    assert length(ExDNS.Records.dns_message(answer, :answers)) == 0
    assert length(ExDNS.Records.dns_message(answer, :authority)) == 0
    assert length(ExDNS.Records.dns_message(answer, :additional)) == 0
  end

  test "test resolve when not authoritative and returning root hints" do
    Application.put_env(:exdns, :use_root_hints, true)
    question = ExDNS.Records.dns_query(name: "notfound.com", type: :dns_terms_const.dns_type_a)
    message = ExDNS.Records.dns_message(questions: [question])
    answer = ExDNS.Resolver.resolve(message, [], :host)
    assert ExDNS.Records.dns_message(answer, :aa)
    assert ExDNS.Records.dns_message(answer, :rc) == :dns_terms_const.dns_rcode_noerror
    assert length(ExDNS.Records.dns_message(answer, :answers)) == 0
    assert length(ExDNS.Records.dns_message(answer, :authority)) > 0
    assert length(ExDNS.Records.dns_message(answer, :additional)) > 0
    Application.put_env(:exdns, :use_root_hints, false)
  end

  test "test any wildcard" do
    {:ok, zone} = ExDNS.Zone.Cache.get_zone("wtest.com")
    assert zone.authority != :undefined
    question = ExDNS.Records.dns_query(name: "fwejfiwerrfj.something.wtest.com", type: :dns_terms_const.dns_type_a)
    message = ExDNS.Records.dns_message(questions: [question])
    answer = ExDNS.Resolver.resolve(message, zone.authority, :host)
    assert ExDNS.Records.dns_message(answer, :aa)
    assert length(ExDNS.Records.dns_message(answer, :answers)) > 0
    assert length(ExDNS.Records.dns_message(answer, :authority)) == 0
    assert length(ExDNS.Records.dns_message(answer, :additional)) == 0
  end

  test "cname and wildcard at root" do
    {:ok, zone} = ExDNS.Zone.Cache.get_zone("wtest.com")
    assert zone.authority != :undefined
    question = ExDNS.Records.dns_query(name: "secure.wtest.com", type: :dns_terms_const.dns_type_a)
    message = ExDNS.Records.dns_message(questions: [question])
    answer = ExDNS.Resolver.resolve(message, zone.authority, :host)
    assert ExDNS.Records.dns_message(answer, :aa)
    assert length(ExDNS.Records.dns_message(answer, :answers)) == 0
    assert length(ExDNS.Records.dns_message(answer, :authority)) > 0
    assert length(ExDNS.Records.dns_message(answer, :additional)) == 0
  end

  test "cname and wildcard but no correct type" do
    {:ok, zone} = ExDNS.Zone.Cache.get_zone("test.com")
    assert zone.authority != :undefined
    question = ExDNS.Records.dns_query(name: "yo.test.test.com", type: :dns_terms_const.dns_type_aaaa)
    message = ExDNS.Records.dns_message(questions: [question])
    answer = ExDNS.Resolver.resolve(message, zone.authority, :host)
    assert ExDNS.Records.dns_message(answer, :aa)
    assert length(ExDNS.Records.dns_message(answer, :answers)) > 0
    assert length(ExDNS.Records.dns_message(answer, :authority)) > 0
    assert length(ExDNS.Records.dns_message(answer, :additional)) == 0
  end

  test "same record only appears in answer set once" do
    {:ok, zone} = ExDNS.Zone.Cache.get_zone("example.com")
    assert zone.authority != :undefined
    question = ExDNS.Records.dns_query(name: "double.example.com", type: :dns_terms_const.dns_type_a)
    message = ExDNS.Records.dns_message(questions: [question])
    answer = ExDNS.Resolver.resolve(message, zone.authority, :host)
    assert ExDNS.Records.dns_message(answer, :aa)
    assert length(ExDNS.Records.dns_message(answer, :answers)) == 1
    assert length(ExDNS.Records.dns_message(answer, :authority)) == 0
    assert length(ExDNS.Records.dns_message(answer, :additional)) == 0
  end


  test "parent?" do
    assert ExDNS.Resolver.parent?("example.com", "example.com")
  end


  test "type matched records" do
    soa_rr = ExDNS.Records.dns_rr(type: :dns_terms_const.dns_type_soa)
    a_rr = ExDNS.Records.dns_rr(type: :dns_terms_const.dns_type_a)
    records = [soa_rr, a_rr]
    assert ExDNS.Resolver.type_match_records(records, :dns_terms_const.dns_type_soa) == [soa_rr]
    assert ExDNS.Resolver.type_match_records(records, :dns_terms_const.dns_type_any) == [soa_rr, a_rr]
    assert ExDNS.Resolver.type_match_records(records, :dns_terms_const.dns_type_cname) == []
  end


  test "filter records" do
    # TBD
  end


  test "rewrite SOA ttl" do
    soa_rrdata = ExDNS.Records.dns_rrdata_soa(minimum: 60)
    soa_rr = ExDNS.Records.dns_rr(name: "example.com", type: :dns_terms_const.dns_type_soa, ttl: 3600, data: soa_rrdata)
    message = ExDNS.Records.dns_message(authority: [soa_rr])
    assert ExDNS.Resolver.rewrite_soa_ttl(message) |> ExDNS.Records.dns_message(:authority) |> List.last |> ExDNS.Records.dns_rr(:ttl) == 60
  end


  test "additional processing" do
    # TBD
  end

  test "requires additional processing with no answers returns the names that are being checked" do
    assert ExDNS.Resolver.requires_additional_processing([], [:name]) == [:name]
  end


  test "check_dnssec" do
    opt_rr = ExDNS.Records.dns_optrr(dnssec: true)
    message = ExDNS.Records.dns_message(additional: [opt_rr])
    question = ExDNS.Records.dns_query(name: "example.com")
    assert ExDNS.Resolver.check_dnssec(message, :host, question)
  end

end
