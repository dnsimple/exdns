defmodule Exdns.QueryThrottleTest do
  use ExUnit.Case, async: false
  require Exdns.Records
  require Logger

  @ip {1, 2, 3, 4}

  setup do
    Exdns.QueryThrottle.clear()
  end

  test "throttle does not throttle TCP" do
    assert Exdns.QueryThrottle.throttle(
             test_message(:dns_terms_const.dns_type_any()),
             {:tcp, @ip}
           ) == :ok

    Exdns.QueryThrottle.clear()
  end

  test "throttle allows 1 UDP ANY queries" do
    assert Exdns.QueryThrottle.throttle(
             test_message(:dns_terms_const.dns_type_any()),
             {:udp, @ip}
           ) == {:ok, @ip, 1}
  end

  test "throttle throttles 2 UDP ANY queries" do
    message = test_message(:dns_terms_const.dns_type_any())
    assert Exdns.QueryThrottle.throttle(message, {:udp, @ip}) == {:ok, @ip, 1}
    assert Exdns.QueryThrottle.throttle(message, {:udp, @ip}) == {:throttled, @ip, 2}
  end

  test "throttle never throttles UDP non-ANY queries" do
    assert Exdns.QueryThrottle.throttle(test_message(:dns_terms_const.dns_type_a()), {:udp, @ip}) ==
             :ok
  end

  test "sweep the throttle" do
    message = test_message(:dns_terms_const.dns_type_any())
    Exdns.Storage.insert(:host_throttle, {@ip, {10, Exdns.timestamp()}})
    assert Exdns.QueryThrottle.throttle(message, {:udp, @ip}) == {:throttled, @ip, 11}
    Exdns.Storage.insert(:host_throttle, {@ip, {10, Exdns.timestamp() - 61}})
    Exdns.QueryThrottle.sweep()
    assert Exdns.QueryThrottle.throttle(message, {:udp, @ip}) == {:ok, @ip, 1}
  end

  defp test_message(question_type) do
    question = Exdns.Records.dns_query()
    question = Exdns.Records.dns_query(question, type: question_type)
    Exdns.Records.dns_message(Exdns.Records.dns_message(), questions: [question])
  end
end
