defmodule ExDNS.EncoderTest do
  use ExUnit.Case, async: true
  require ExDNS.Records

  test "encode message" do
    message = ExDNS.Records.dns_message()
    {false, bin} = ExDNS.Encoder.encode_message(message)
    assert ExDNS.Decoder.decode_message(bin) == message 
  end
end
