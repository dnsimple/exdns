defmodule ExDNS.QueryThrottleTest do
  use ExUnit.Case, async: false
  require ExDNS.Records
  require Logger

  @ip {1, 2, 3, 4}

  setup do
    ExDNS.QueryThrottle.clear()
  end

  test "throttle does not throttle TCP" do
    assert ExDNS.QueryThrottle.throttle(test_message(:dns_terms_const.dns_type_any), {:tcp, @ip}) == :ok
    ExDNS.QueryThrottle.clear()
  end

  test "throttle allows 1 UDP ANY queries" do
    assert ExDNS.QueryThrottle.throttle(test_message(:dns_terms_const.dns_type_any), {:udp, @ip}) == {:ok, @ip, 1}
  end

  test "throttle throttles 2 UDP ANY queries" do
    message = test_message(:dns_terms_const.dns_type_any)
    assert ExDNS.QueryThrottle.throttle(message, {:udp, @ip}) == {:ok, @ip, 1}
    assert ExDNS.QueryThrottle.throttle(message, {:udp, @ip}) == {:throttled, @ip, 2}
  end

  test "throttle never throttles UDP non-ANY queries" do
    assert ExDNS.QueryThrottle.throttle(test_message(:dns_terms_const.dns_type_a), {:udp, @ip}) == :ok
  end

  test "sweep the throttle" do
    message = test_message(:dns_terms_const.dns_type_any)
    ExDNS.Storage.insert(:host_throttle, {@ip, {10, ExDNS.timestamp()}})
    assert ExDNS.QueryThrottle.throttle(message, {:udp, @ip}) == {:throttled, @ip, 11}
    ExDNS.Storage.insert(:host_throttle, {@ip, {10, ExDNS.timestamp() - 61}})
    ExDNS.QueryThrottle.sweep()
    assert ExDNS.QueryThrottle.throttle(message, {:udp, @ip}) == {:ok, @ip, 1}
  end

  defp test_message(question_type) do
    question = ExDNS.Records.dns_query()
    question = ExDNS.Records.dns_query(question, type: question_type)
    ExDNS.Records.dns_message(ExDNS.Records.dns_message(), questions: [question])
  end
end
