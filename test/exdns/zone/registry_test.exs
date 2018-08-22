defmodule Exdns.Zone.RegistryTest do
  use ExUnit.Case, async: true

  test "register module" do
    assert Exdns.Zone.Registry.register(:mod)
    assert Exdns.Zone.Registry.get_all() == [:mod]
    Exdns.Zone.Registry.clear()
  end

  test "register modules" do
    assert Exdns.Zone.Registry.register([:mod1, :mod2])
    assert Exdns.Zone.Registry.get_all() == [:mod1, :mod2]
    Exdns.Zone.Registry.clear()
  end
end
