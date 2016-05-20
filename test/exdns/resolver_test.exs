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
    question = Exdns.Records.dns_query(name: "example.com", type: :dns_terms_const.dns_type_a)
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

  test "test resolve when not authoritative" do
    question = Exdns.Records.dns_query(name: "notfound.com", type: :dns_terms_const.dns_type_a)
    message = Exdns.Records.dns_message(questions: [question])
    answer = Exdns.Resolver.resolve(message, [], :host)
    assert length(Exdns.Records.dns_message(answer, :answers)) == 0
    assert length(Exdns.Records.dns_message(answer, :authority)) == 0
    assert length(Exdns.Records.dns_message(answer, :additional)) == 0
  end


  test "parent?" do
    assert Exdns.Resolver.parent?("example.com", "example.com")
  end


  test "rewrite SOA ttl" do
    soa_rrdata = Exdns.Records.dns_rrdata_soa(minimum: 60)
    soa_rr = Exdns.Records.dns_rr(name: "example.com", type: :dns_terms_const.dns_type_soa, ttl: 3600, data: soa_rrdata)
    message = Exdns.Records.dns_message(authority: [soa_rr])
    assert Exdns.Resolver.rewrite_soa_ttl(message) |> Exdns.Records.dns_message(:authority) |> List.last |> Exdns.Records.dns_rr(:ttl) == 60
  end


  test "requires additional processing with no answers returns the names that are being checked" do
    assert Exdns.Resolver.requires_additional_processing([], [:name]) == [:name]
  end


  test "check_dnssec" do
    assert Exdns.Resolver.check_dnssec(:message, :host, :question) == false
  end

end
