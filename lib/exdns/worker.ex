defmodule Exdns.Worker do
  @moduledoc """
  Servers hand off requests to workers for processing, freeing up server processes
  so they can continue receiving data from the network.
  """

  use GenServer
  require Logger
  require Record
  require Exdns.Records

  @max_packet_size 512

  def start_link([]) do
    GenServer.start_link(__MODULE__, []) 
  end

  # GenServer callbacks
  def init([]) do
    {:ok, %{}}
  end

  def handle_call({:tcp_query, socket, bin}, _from, state) do
    {:reply, handle_tcp_dns_query(socket, bin), state}
  end

  def handle_cast({:udp_query, socket, host, port, bin}, state) do
    handle_udp_dns_query(socket, host, port, bin)
    {:noreply, state}
  end

  # Internal methods

  # TCP handling

  def handle_tcp_dns_query(socket, <<_len::16, bin::binary>>) do
    case :inet.peername(socket) do
      {:ok, {address, _port}} ->
        Exdns.Events.notify({:start_tcp, [{:host, address}]})

        result = case bin do
          <<>> -> :ok
          _ ->
            case Exdns.Decoder.decode_message(bin) do
              {:truncated, _, _} ->
                :ok
              {:trailing_garbage, decoded_message, _} ->
                handle_decoded_tcp_message(decoded_message, socket, address)
              {:error, _, _} ->
                :ok
              decoded_message ->
                handle_decoded_tcp_message(decoded_message, socket, address)
            end
        end

        Exdns.Events.notify({:end_tcp, [{:host, address}]})
        :gen_tcp.close(socket)
      {:error, reason} ->
        Exdns.Events.notify({:tcp_error, reason})
    end
  end

  def handle_tcp_dns_query(socket, bad_packet) do
    :gen_tcp.close(socket)
  end

  def handle_decoded_tcp_message(decoded_message, socket, address) do
    Exdns.Events.notify({:start_handle, :tcp, [{:host, address}]})
    response = Exdns.Handler.handle(decoded_message, {:tcp, address})
    Exdns.Events.notify({:end_handle, :tcp, [{:host, address}]})
    case Exdns.Encoder.encode_message(response) do
      {false, encoded_message} -> send_tcp_message(socket, encoded_message)
      {true, encoded_message, _message} -> send_tcp_message(socket, encoded_message)
      {false, encoded_message, _tsig_mac} -> send_tcp_message(socket, encoded_message)
      {true, encoded_message, _tsig_mac, _message} -> send_tcp_message(socket, encoded_message)
    end
  end

  defp send_tcp_message(socket, encoded_message) do
    bin_length = byte_size(encoded_message)
    tcp_encoded_message = <<bin_length::16, encoded_message::binary()>>
    :gen_tcp.send(socket, tcp_encoded_message)
  end

  # UDP handling

  @spec handle_udp_dns_query(:gen_udp.socket(), :gen_udp.ip(), :inet.port_number(), binary()) :: :ok
  def handle_udp_dns_query(socket, host, port, bin) do
    Exdns.Events.notify({:start_udp, [{:host, host}]})

    case Exdns.Decoder.decode_message(bin) do
      {:trailing_garbage, decoded_message, _} ->
        handle_decoded_udp_message(decoded_message, socket, host, port)
      {_error, _, _} ->
        :ok
      decoded_message ->
        handle_decoded_udp_message(decoded_message, socket, host, port)
    end

    Exdns.Events.notify({:end_udp, [{:host, host}]})
    :ok
  end

  @spec handle_decoded_udp_message(:dns.message(), :gen_udp.socket(), :gen_udp.ip(), :inet.port_number()) :: :ok | {:error, :not_owner | :inet.posix()}
  defp handle_decoded_udp_message(decoded_message, socket, host, port) do
    response = Exdns.Handler.handle(decoded_message, {:udp, host})
    {_, encoded_message} =  Exdns.Encoder.encode_message(response, [{:"max_size", max_payload_size(response)}])
    :gen_udp.send(socket, host, port, encoded_message)
  end

  defp max_payload_size(message) do
    case Exdns.Records.dns_message(message, :additional) do
      [opt|_] when Record.is_record(opt, :dns_optrr) ->
        case Exdns.Records.dns_optrr(opt, :udp_payload_size) do
          [] -> @max_packet_size
          udp_payload_size -> udp_payload_size
        end
      _ -> @max_packet_size
    end
  end

end
