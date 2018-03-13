defmodule ExDNS.EdnsTest do
  require ExDNS.Records

  use ExUnit.Case, async: true

  test "get opts when records are present" do
    message = ExDNS.Records.dns_message
    assert ExDNS.Edns.get_opts(message) == []
  end

  test "get opts when an optrr is present" do
    optrr = ExDNS.Records.dns_optrr(dnssec: true)
    message = ExDNS.Records.dns_message(additional: [optrr])
    assert ExDNS.Edns.get_opts(message) == [{:dnssec, true}]
  end

  test "get opts when an optrr is present and other records" do
    optrr = ExDNS.Records.dns_optrr(dnssec: true)
    rr = ExDNS.Records.dns_rr()
    message = ExDNS.Records.dns_message(additional: [optrr, rr])
    assert ExDNS.Edns.get_opts(message) == [{:dnssec, true}]
  end
end
