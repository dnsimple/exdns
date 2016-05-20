defmodule Exdns.RecordsTest do
  require Exdns.Records

  use ExUnit.Case, async: true

  # Records

  test "dns message construction" do
    message = Exdns.Records.dns_message()
    assert Exdns.Records.dns_message(message, :id) != nil
    assert Exdns.Records.dns_message(message, :qr) == false
    assert Exdns.Records.dns_message(message, :oc) == :dns_terms_const.dns_opcode_query
    assert Exdns.Records.dns_message(message, :aa) == false
    assert Exdns.Records.dns_message(message, :tc) == false
    assert Exdns.Records.dns_message(message, :rd) == false
    assert Exdns.Records.dns_message(message, :ra) == false
    assert Exdns.Records.dns_message(message, :ad) == false
    assert Exdns.Records.dns_message(message, :cd) == false
    assert Exdns.Records.dns_message(message, :rc) == :dns_terms_const.dns_rcode_noerror
    assert Exdns.Records.dns_message(message, :qc) == 0
    assert Exdns.Records.dns_message(message, :anc) == 0
    assert Exdns.Records.dns_message(message, :auc) == 0
    assert Exdns.Records.dns_message(message, :adc) == 0
    assert Exdns.Records.dns_message(message, :questions) == []
    assert Exdns.Records.dns_message(message, :answers) == []
    assert Exdns.Records.dns_message(message, :authority) == []
    assert Exdns.Records.dns_message(message, :additional) == []
  end

  test "dns query construction" do
    question = Exdns.Records.dns_query()
    assert Exdns.Records.dns_query(question, :name) == :undefined
    assert Exdns.Records.dns_query(question, :class) == :dns_terms_const.dns_class_in()
    assert Exdns.Records.dns_query(question, :type) == :undefined
  end

  test "dns resource record construction" do
    rr = Exdns.Records.dns_rr()
    assert Exdns.Records.dns_rr(rr, :name) == :undefined
    assert Exdns.Records.dns_rr(rr, :class) == :dns_terms_const.dns_class_in()
    assert Exdns.Records.dns_rr(rr, :type) == :undefined
    assert Exdns.Records.dns_rr(rr, :ttl) == 0
    assert Exdns.Records.dns_rr(rr, :data) == :undefined
  end

  test "dns resource record data type A construction" do
    rrdata = Exdns.Records.dns_rrdata_a()
    assert Exdns.Records.dns_rrdata_a(rrdata, :ip) == :undefined
  end

  test "dns resource record data type CNAME construction" do
    rrdata = Exdns.Records.dns_rrdata_cname()
    assert Exdns.Records.dns_rrdata_cname(rrdata, :dname) == :undefined
  end

  test "dns resource record data type NS construction" do
    rrdata = Exdns.Records.dns_rrdata_ns()
    assert Exdns.Records.dns_rrdata_ns(rrdata, :dname) == :undefined
  end

  test "dns resource record data type SOA construction" do
    rrdata = Exdns.Records.dns_rrdata_soa()
    assert Exdns.Records.dns_rrdata_soa(rrdata, :mname) == :undefined
    assert Exdns.Records.dns_rrdata_soa(rrdata, :rname) == :undefined
    assert Exdns.Records.dns_rrdata_soa(rrdata, :serial) == :undefined
    assert Exdns.Records.dns_rrdata_soa(rrdata, :refresh) == :undefined
    assert Exdns.Records.dns_rrdata_soa(rrdata, :retry) == :undefined
    assert Exdns.Records.dns_rrdata_soa(rrdata, :expire) == :undefined
    assert Exdns.Records.dns_rrdata_soa(rrdata, :minimum) == :undefined
  end

  # Utility functions

  test "minimum soa TTL" do
    record = Exdns.Records.dns_rr(ttl: 10)
    data = Exdns.Records.dns_rrdata_soa(minimum: 20)
    assert Exdns.Records.dns_rr(Exdns.Records.minimum_soa_ttl(record, data), :ttl) == 10

    data = Exdns.Records.dns_rrdata_soa(minimum: 5)
    assert Exdns.Records.dns_rr(Exdns.Records.minimum_soa_ttl(record, data), :ttl) == 5
  end

  # Matchers

  test "match name" do
    name = "example.com"
    soa_rr = Exdns.Records.dns_rr(name: name, type: :dns_terms_const.dns_type_soa)
    a_rr = Exdns.Records.dns_rr(name: name, type: :dns_terms_const.dns_type_a)
    cname_rr = Exdns.Records.dns_rr(name: "www.#{name}", type: :dns_terms_const.dns_type_cname)
    assert Enum.filter([soa_rr, a_rr, cname_rr], Exdns.Records.match_name(name)) == [soa_rr, a_rr]
  end

  test "match type" do
    soa_rr = Exdns.Records.dns_rr(type: :dns_terms_const.dns_type_soa)
    a_rr = Exdns.Records.dns_rr(type: :dns_terms_const.dns_type_a)
    assert Enum.filter([soa_rr, a_rr], Exdns.Records.match_type(:dns_terms_const.dns_type_soa)) == [soa_rr]
  end

  test "match name and type" do
    name = "example.com"
    soa_rr = Exdns.Records.dns_rr(name: name, type: :dns_terms_const.dns_type_soa)
    a_rr = Exdns.Records.dns_rr(name: name, type: :dns_terms_const.dns_type_a)
    a_rr2 = Exdns.Records.dns_rr(name: "www.#{name}", type: :dns_terms_const.dns_type_a)
    assert Enum.filter([soa_rr, a_rr, a_rr2], Exdns.Records.match_name_and_type(name, :dns_terms_const.dns_type_a)) == [a_rr]
  end

  test "match types" do
    soa_rr = Exdns.Records.dns_rr(type: :dns_terms_const.dns_type_soa)
    a_rr = Exdns.Records.dns_rr(type: :dns_terms_const.dns_type_a)
    cname_rr = Exdns.Records.dns_rr(type: :dns_terms_const.dns_type_cname)
    types = [:dns_terms_const.dns_type_a, :dns_terms_const.dns_type_cname]
    assert Enum.filter([soa_rr, a_rr, cname_rr], Exdns.Records.match_types(types)) == [a_rr, cname_rr]
  end

  test "match wildcard" do
    name = "example.com"
    rr = Exdns.Records.dns_rr(name: name)
    wildcard_rr = Exdns.Records.dns_rr(name: "*.#{name}")
    assert Enum.filter([rr, wildcard_rr], Exdns.Records.match_wildcard()) == [wildcard_rr]
  end

  test "match delegation" do
    name = "ns1.example.com"
    rr = Exdns.Records.dns_rr(data: Exdns.Records.dns_rrdata_ns(dname: name))
    assert Enum.all?([rr], Exdns.Records.match_delegation(name))
  end

end
