defmodule ExDNS.RecordsTest do
  use ExUnit.Case, async: true
  require ExDNS.Records

  # Records

  test "dns message construction" do
    message = ExDNS.Records.dns_message()
    assert ExDNS.Records.dns_message(message, :id) != nil
    assert ExDNS.Records.dns_message(message, :qr) == false
    assert ExDNS.Records.dns_message(message, :oc) == :dns_terms_const.dns_opcode_query
    assert ExDNS.Records.dns_message(message, :aa) == false
    assert ExDNS.Records.dns_message(message, :tc) == false
    assert ExDNS.Records.dns_message(message, :rd) == false
    assert ExDNS.Records.dns_message(message, :ra) == false
    assert ExDNS.Records.dns_message(message, :ad) == false
    assert ExDNS.Records.dns_message(message, :cd) == false
    assert ExDNS.Records.dns_message(message, :rc) == :dns_terms_const.dns_rcode_noerror
    assert ExDNS.Records.dns_message(message, :qc) == 0
    assert ExDNS.Records.dns_message(message, :anc) == 0
    assert ExDNS.Records.dns_message(message, :auc) == 0
    assert ExDNS.Records.dns_message(message, :adc) == 0
    assert ExDNS.Records.dns_message(message, :questions) == []
    assert ExDNS.Records.dns_message(message, :answers) == []
    assert ExDNS.Records.dns_message(message, :authority) == []
    assert ExDNS.Records.dns_message(message, :additional) == []
  end

  test "dns query construction" do
    question = ExDNS.Records.dns_query()
    assert ExDNS.Records.dns_query(question, :name) == :undefined
    assert ExDNS.Records.dns_query(question, :class) == :dns_terms_const.dns_class_in()
    assert ExDNS.Records.dns_query(question, :type) == :undefined
  end

  test "dns resource record construction" do
    rr = ExDNS.Records.dns_rr()
    assert ExDNS.Records.dns_rr(rr, :name) == :undefined
    assert ExDNS.Records.dns_rr(rr, :class) == :dns_terms_const.dns_class_in()
    assert ExDNS.Records.dns_rr(rr, :type) == :undefined
    assert ExDNS.Records.dns_rr(rr, :ttl) == 0
    assert ExDNS.Records.dns_rr(rr, :data) == :undefined
  end

  test "dns resource record data type A construction" do
    rrdata = ExDNS.Records.dns_rrdata_a()
    assert ExDNS.Records.dns_rrdata_a(rrdata, :ip) == :undefined
  end

  test "dns resource record data type AAAA construction" do
    rrdata = ExDNS.Records.dns_rrdata_aaaa()
    assert ExDNS.Records.dns_rrdata_aaaa(rrdata, :ip) == :undefined
  end

  test "dns resource record data type CNAME construction" do
    rrdata = ExDNS.Records.dns_rrdata_cname()
    assert ExDNS.Records.dns_rrdata_cname(rrdata, :dname) == :undefined
  end

  test "dns resource record data type HINFO construction" do
    rrdata = ExDNS.Records.dns_rrdata_hinfo()
    assert ExDNS.Records.dns_rrdata_hinfo(rrdata, :cpu) == :undefined
    assert ExDNS.Records.dns_rrdata_hinfo(rrdata, :os) == :undefined
  end

  test "dns resource record data type MX construction" do
    rrdata = ExDNS.Records.dns_rrdata_mx()
    assert ExDNS.Records.dns_rrdata_mx(rrdata, :exchange) == :undefined
    assert ExDNS.Records.dns_rrdata_mx(rrdata, :preference) == :undefined
  end

  test "dns resource record data type NAPTR construction" do
    rrdata = ExDNS.Records.dns_rrdata_naptr()
    assert ExDNS.Records.dns_rrdata_naptr(rrdata, :order) == :undefined
    assert ExDNS.Records.dns_rrdata_naptr(rrdata, :preference) == :undefined
    assert ExDNS.Records.dns_rrdata_naptr(rrdata, :flags) == :undefined
    assert ExDNS.Records.dns_rrdata_naptr(rrdata, :services) == :undefined
    assert ExDNS.Records.dns_rrdata_naptr(rrdata, :regexp) == :undefined
    assert ExDNS.Records.dns_rrdata_naptr(rrdata, :replacement) == :undefined
  end

  test "dns resource record data type NS construction" do
    rrdata = ExDNS.Records.dns_rrdata_ns()
    assert ExDNS.Records.dns_rrdata_ns(rrdata, :dname) == :undefined
  end

  test "dns resource record data type PTR construction" do
    rrdata = ExDNS.Records.dns_rrdata_ptr()
    assert ExDNS.Records.dns_rrdata_ptr(rrdata, :dname) == :undefined
  end

  test "dns resource record data type RP construction" do
    rrdata = ExDNS.Records.dns_rrdata_rp()
    assert ExDNS.Records.dns_rrdata_rp(rrdata, :mbox) == :undefined
    assert ExDNS.Records.dns_rrdata_rp(rrdata, :txt) == :undefined
  end

  test "dns resource record data type SOA construction" do
    rrdata = ExDNS.Records.dns_rrdata_soa()
    assert ExDNS.Records.dns_rrdata_soa(rrdata, :mname) == :undefined
    assert ExDNS.Records.dns_rrdata_soa(rrdata, :rname) == :undefined
    assert ExDNS.Records.dns_rrdata_soa(rrdata, :serial) == :undefined
    assert ExDNS.Records.dns_rrdata_soa(rrdata, :refresh) == :undefined
    assert ExDNS.Records.dns_rrdata_soa(rrdata, :retry) == :undefined
    assert ExDNS.Records.dns_rrdata_soa(rrdata, :expire) == :undefined
    assert ExDNS.Records.dns_rrdata_soa(rrdata, :minimum) == :undefined
  end

  test "dns resource record data type SPF construction" do
    rrdata = ExDNS.Records.dns_rrdata_spf()
    assert ExDNS.Records.dns_rrdata_spf(rrdata, :spf) == :undefined
  end

  test "dns resource record data type SRV construction" do
    rrdata = ExDNS.Records.dns_rrdata_srv()
    assert ExDNS.Records.dns_rrdata_srv(rrdata, :priority) == :undefined
    assert ExDNS.Records.dns_rrdata_srv(rrdata, :weight) == :undefined
    assert ExDNS.Records.dns_rrdata_srv(rrdata, :port) == :undefined
    assert ExDNS.Records.dns_rrdata_srv(rrdata, :target) == :undefined
  end

  test "dns resource record data type SSHFP construction" do
    rrdata = ExDNS.Records.dns_rrdata_sshfp()
    assert ExDNS.Records.dns_rrdata_sshfp(rrdata, :alg) == :undefined
    assert ExDNS.Records.dns_rrdata_sshfp(rrdata, :fp_type) == :undefined
    assert ExDNS.Records.dns_rrdata_sshfp(rrdata, :fp) == :undefined
  end

  test "dns resource record data type TXT construction" do
    rrdata = ExDNS.Records.dns_rrdata_txt()
    assert ExDNS.Records.dns_rrdata_txt(rrdata, :txt) == :undefined
  end

  # Utility functions

  test "minimum soa TTL" do
    record = ExDNS.Records.dns_rr(ttl: 10)
    data = ExDNS.Records.dns_rrdata_soa(minimum: 20)
    assert ExDNS.Records.dns_rr(ExDNS.Records.minimum_soa_ttl(record, data), :ttl) == 10

    data = ExDNS.Records.dns_rrdata_soa(minimum: 5)
    assert ExDNS.Records.dns_rr(ExDNS.Records.minimum_soa_ttl(record, data), :ttl) == 5
  end

  # Matchers

  test "match name" do
    name = "example.com"
    soa_rr = ExDNS.Records.dns_rr(name: name, type: :dns_terms_const.dns_type_soa)
    a_rr = ExDNS.Records.dns_rr(name: name, type: :dns_terms_const.dns_type_a)
    cname_rr = ExDNS.Records.dns_rr(name: "www.#{name}", type: :dns_terms_const.dns_type_cname)
    assert Enum.filter([soa_rr, a_rr, cname_rr], ExDNS.Records.match_name(name)) == [soa_rr, a_rr]
  end

  test "match type" do
    soa_rr = ExDNS.Records.dns_rr(type: :dns_terms_const.dns_type_soa)
    a_rr = ExDNS.Records.dns_rr(type: :dns_terms_const.dns_type_a)
    assert Enum.filter([soa_rr, a_rr], ExDNS.Records.match_type(:dns_terms_const.dns_type_soa)) == [soa_rr]
  end

  test "match name and type" do
    name = "example.com"
    soa_rr = ExDNS.Records.dns_rr(name: name, type: :dns_terms_const.dns_type_soa)
    a_rr = ExDNS.Records.dns_rr(name: name, type: :dns_terms_const.dns_type_a)
    a_rr2 = ExDNS.Records.dns_rr(name: "www.#{name}", type: :dns_terms_const.dns_type_a)
    assert Enum.filter([soa_rr, a_rr, a_rr2], ExDNS.Records.match_name_and_type(name, :dns_terms_const.dns_type_a)) == [a_rr]
  end

  test "match types" do
    soa_rr = ExDNS.Records.dns_rr(type: :dns_terms_const.dns_type_soa)
    a_rr = ExDNS.Records.dns_rr(type: :dns_terms_const.dns_type_a)
    cname_rr = ExDNS.Records.dns_rr(type: :dns_terms_const.dns_type_cname)
    types = [:dns_terms_const.dns_type_a, :dns_terms_const.dns_type_cname]
    assert Enum.filter([soa_rr, a_rr, cname_rr], ExDNS.Records.match_types(types)) == [a_rr, cname_rr]
  end

  test "match wildcard" do
    name = "example.com"
    rr = ExDNS.Records.dns_rr(name: name)
    wildcard_rr = ExDNS.Records.dns_rr(name: "*.#{name}")
    assert Enum.filter([rr, wildcard_rr], ExDNS.Records.match_wildcard()) == [wildcard_rr]
  end

  test "match delegation" do
    name = "ns1.example.com"
    rr = ExDNS.Records.dns_rr(data: ExDNS.Records.dns_rrdata_ns(dname: name))
    assert Enum.all?([rr], ExDNS.Records.match_delegation(name))
  end

  # Replacement functions

  test "replace name" do
    rr = ExDNS.Records.dns_rr(name: "foo")
    assert Enum.map([rr], ExDNS.Records.replace_name("bar")) == [ExDNS.Records.dns_rr(name: "bar")]
  end

end
