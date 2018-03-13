defmodule ExDNS.WorkerTest do
  use ExUnit.Case, async: false
  require ExDNS.Records

  setup do
    {:ok, worker} = ExDNS.Worker.start_link([])
    {:ok, worker: worker}
  end

  test "handle UDP query" do
    message = ExDNS.Records.dns_message()

    {:ok, socket} = :gen_udp.open(0)
    {false, bin} = ExDNS.Encoder.encode_message(message)
    assert ExDNS.Worker.handle_udp_dns_query(socket, :host, :port, bin)
    :gen_udp.close(socket)
  end

  test "handle TCP query" do
    message = ExDNS.Records.dns_message()
    {:ok, socket} = :gen_tcp.listen(0, [])
    {false, bin} = ExDNS.Encoder.encode_message(message)
    assert ExDNS.Worker.handle_tcp_dns_query(socket, <<byte_size(bin)>> <> bin)
    :gen_tcp.close(socket)
  end
end
