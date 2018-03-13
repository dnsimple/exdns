defmodule ExDNS.Server.UDPServerTest do
  use ExUnit.Case, async: false
  require ExDNS.Records

  @localhost {127,0,0,1}
  @localhost6 {0,0,0,0,0,0,0,1}

  test "server start" do 
    assert ExDNS.Server.UDPServer.start_link(:test, :inet, @localhost, 12345)
    ExDNS.Server.UDPServer.stop(:test)
  end

  test "server start with inet6" do
    assert ExDNS.Server.UDPServer.start_link(:test, :inet6, @localhost6, 12345)
    ExDNS.Server.UDPServer.stop(:test)
  end

  test "handle timeout message" do
    {:ok, server} = ExDNS.Server.UDPServer.start_link(:test, :inet, @localhost, 12346)
    assert send(server, :timeout)
    ExDNS.Server.UDPServer.stop(:test)
  end

  test "handle UDP message" do
    {:ok, server} = ExDNS.Server.UDPServer.start_link(:test, :inet, {127,0,0,1}, 12347)
    {:ok, socket} = :gen_udp.open(0)
    message = ExDNS.Records.dns_message()
    {false, bin} = ExDNS.Encoder.encode_message(message)
    assert send(server, {:udp, socket, :host, :port, bin})
    :gen_udp.close(socket)
    ExDNS.Server.UDPServer.stop(:test)
  end

  test "handle request with no workers in the queue" do
    {:ok, socket} = :gen_udp.open(0)
    message = ExDNS.Records.dns_message()
    {false, bin} = ExDNS.Encoder.encode_message(message)
    state = %{port: :port, socket: socket, workers: :queue.new()}
    assert ExDNS.Server.UDPServer.handle_request(socket, :host, :port, bin, state)
    :gen_udp.close(socket)
  end

  test "handle request with workers in the queue" do
    {:ok, socket} = :gen_udp.open(0)
    message = ExDNS.Records.dns_message()
    {false, bin} = ExDNS.Encoder.encode_message(message)
    {:ok, worker_pid} = ExDNS.Worker.start_link([])
    queue = :queue.new()
    workers = :queue.in(worker_pid, queue)
    state = %{port: :port, socket: socket, workers: workers}
    assert ExDNS.Server.UDPServer.handle_request(socket, :host, :port, bin, state)
    :gen_udp.close(socket)
  end
end
