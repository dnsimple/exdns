defmodule Exdns.Server.TcpServerTest do
  use ExUnit.Case, async: false
  require Exdns.Records

  test "server start" do
    assert Exdns.Server.TcpServer.start_link(:test, :inet, {127, 0, 0, 1}, 12345)
    Exdns.Server.TcpServer.stop(:test)
  end

  test "server start with inet6" do
    assert Exdns.Server.TcpServer.start_link(:test, :inet, {0, 0, 0, 0, 0, 0, 0, 1}, 12345)
    Exdns.Server.TcpServer.stop(:test)
  end

  test "handle TCP message" do
    {:ok, server} = Exdns.Server.TcpServer.start_link(:test, :inet, {127, 0, 0, 1}, 12347)
    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 12347, [])
    message = Exdns.Records.dns_message()
    {false, bin} = Exdns.Encoder.encode_message(message)
    assert send(server, {:tcp, socket, bin})
    :gen_tcp.close(socket)
    Exdns.Server.TcpServer.stop(:test)
  end
end
