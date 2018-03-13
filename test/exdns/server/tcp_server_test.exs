defmodule ExDNS.Server.TCPServerTest do
  use ExUnit.Case, async: false
  require ExDNS.Records

  test "server start" do
    assert ExDNS.Server.TCPServer.start_link(:test, :inet, {127,0,0,1}, 12345)
    ExDNS.Server.TCPServer.stop(:test)
  end

  test "server start with inet6" do
    assert ExDNS.Server.TCPServer.start_link(:test, :inet, {0,0,0,0,0,0,0,1}, 12345)
    ExDNS.Server.TCPServer.stop(:test)
  end

  test "handle TCP message" do
    {:ok, server} = ExDNS.Server.TCPServer.start_link(:test, :inet, {127,0,0,1}, 12347)
    {:ok, socket} = :gen_tcp.connect({127,0,0,1}, 12347, [])
    message = ExDNS.Records.dns_message()
    {false, bin} = ExDNS.Encoder.encode_message(message)
    assert send(server, {:tcp, socket, bin})
    :gen_tcp.close(socket)
    ExDNS.Server.TCPServer.stop(:test)
  end
end
