defmodule Exdns.EncoderTest do
  use ExUnit.Case, async: true
  require Exdns.Records

  test "encode message" do
    message = Exdns.Records.dns_message()
    {false, bin} = Exdns.Encoder.encode_message(message)
    assert Exdns.Decoder.decode_message(bin) == message 
  end
end
