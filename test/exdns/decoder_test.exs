defmodule Exdns.DecoderTest do
  use ExUnit.Case, async: true
  require Exdns.Records

  test "decode empty message" do
    assert Exdns.Decoder.decode_message(<<>>) == {:formerr, :undefined, ""}
  end

  test "decode message" do
    bin = <<98, 36, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
    message = Exdns.Decoder.decode_message(bin)
    assert Exdns.Records.dns_message(message, :id) > 0
  end
end
