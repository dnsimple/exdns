defmodule ExDNS.TxtTest do
  use ExUnit.Case, async: true

  test "parse empty string" do
    assert ExDNS.Txt.parse("") == []
  end

  test "parse simple string" do
    assert ExDNS.Txt.parse("test") == ["test"]
  end

  test "parse long string" do
    assert ExDNS.Txt.parse(String.duplicate("x", 270)) == [String.duplicate("x", 255), String.duplicate("x", 15)]
  end

  test "parse string with escaped quotes" do
    assert ExDNS.Txt.parse("\"test\" \"test\"") == ["test","test"]
  end

  test "parse escape character by itself" do
    assert ExDNS.Txt.parse("\\") == ["\\"]
  end

  test "parse escaped slash followed by a semi-colon" do
    assert ExDNS.Txt.parse("test\\;") == ["test\\;"]
  end

  test "parse escaped slash as final character" do
    assert ExDNS.Txt.parse("test\\") == ["test\\"]
  end

  test "parse quoted string with escaped quote" do
    assert ExDNS.Txt.parse("test\"") == ["test\""]
  end
end
