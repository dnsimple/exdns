defmodule Exdns.HandlerTest do
  use ExUnit.Case, async: true
  require Exdns.Records

  test "handle trailing garbage" do
    message = Exdns.Records.dns_message()
    context = {:unknown, :host}
    Exdns.Handler.handle({:trailing_garbage, message, :unknown}, context)
  end

  test "handle DNS message" do
    message = Exdns.Records.dns_message()
    context = {:unknown, :host}
    Exdns.Handler.handle(message, context)
  end

  test "handle bad message" do
    message = :message
    context = {:unknown, :host}
    Exdns.Handler.handle(message, context)
  end
end
