defmodule Exdns.EdnsTest do
  require Exdns.Records

  use ExUnit.Case, async: true

  test "get opts when records are present" do
    message = Exdns.Records.dns_message
    assert Exdns.Edns.get_opts(message) == []
  end

  test "get opts when an optrr is present" do
    optrr = Exdns.Records.dns_optrr(dnssec: true)
    message = Exdns.Records.dns_message(additional: [optrr])
    assert Exdns.Edns.get_opts(message) == [{:dnssec, true}]
  end

  test "get opts when an optrr is present and other records" do
    optrr = Exdns.Records.dns_optrr(dnssec: true)
    rr = Exdns.Records.dns_rr()
    message = Exdns.Records.dns_message(additional: [optrr, rr])
    assert Exdns.Edns.get_opts(message) == [{:dnssec, true}]
  end
end
