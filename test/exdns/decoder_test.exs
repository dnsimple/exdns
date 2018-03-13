defmodule ExDNS.DecoderTest do
  use ExUnit.Case, async: true
  require ExDNS.Records

  test "decode empty message" do
    assert ExDNS.Decoder.decode_message(<<>>) == {:formerr, :undefined, ""}
  end

  test "decode message" do
    bin = <<98, 36, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
    message = ExDNS.Decoder.decode_message(bin)
    assert ExDNS.Records.dns_message(message, :id) > 0
  end
end
