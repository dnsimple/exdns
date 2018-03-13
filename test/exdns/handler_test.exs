defmodule ExDNS.HandlerTest do
  use ExUnit.Case, async: true
  require ExDNS.Records

  test "handle trailing garbage" do
    message = ExDNS.Records.dns_message
    context = {:unknown, :host}
    ExDNS.Handler.handle({:trailing_garbage, message, :unknown}, context)
  end

  test "handle DNS message" do
    message = ExDNS.Records.dns_message
    context = {:unknown, :host}
    ExDNS.Handler.handle(message, context)
  end

  test "handle bad message" do
    message = :message
    context = {:unknown, :host}
    ExDNS.Handler.handle(message, context)
  end
end
