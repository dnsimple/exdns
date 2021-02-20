defmodule Exdns.TxtTest do
  use ExUnit.Case, async: true

  test "parse empty string" do
    assert Exdns.Txt.parse("") == []
  end

  test "parse simple string" do
    assert Exdns.Txt.parse("test") == ["test"]
  end

  test "parse long string" do
    assert Exdns.Txt.parse(String.duplicate("x", 270)) == [
             String.duplicate("x", 255),
             String.duplicate("x", 15)
           ]
  end

  test "parse string with escaped quotes" do
    assert Exdns.Txt.parse("\"test\" \"test\"") == ["test", "test"]
  end

  test "parse escape character by itself" do
    assert Exdns.Txt.parse("\\") == ["\\"]
  end

  test "parse escaped slash followed by a semi-colon" do
    assert Exdns.Txt.parse("test\\;") == ["test\\;"]
  end

  test "parse escaped slash as final character" do
    assert Exdns.Txt.parse("test\\") == ["test\\"]
  end

  test "parse quoted string with escaped quote" do
    assert Exdns.Txt.parse("test\"") == ["test\""]
  end
end
