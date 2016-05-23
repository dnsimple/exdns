defmodule Exdns.ZoneParser.RegistryTest do
  use ExUnit.Case, async: true

  test "register module" do
    assert Exdns.ZoneParser.Registry.register(:mod)
    assert Exdns.ZoneParser.Registry.get_all == [:mod]
    Exdns.ZoneParser.Registry.clear
  end

  test "register modules" do
    assert Exdns.ZoneParser.Registry.register([:mod1, :mod2])
    assert Exdns.ZoneParser.Registry.get_all == [:mod1, :mod2]
    Exdns.ZoneParser.Registry.clear
  end
end
