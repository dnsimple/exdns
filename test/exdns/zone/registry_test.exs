defmodule ExDNS.Zone.RegistryTest do
  use ExUnit.Case, async: true

  test "register module" do
    assert ExDNS.Zone.Registry.register(:mod)
    assert ExDNS.Zone.Registry.get_all == [:mod]
    ExDNS.Zone.Registry.clear
  end

  test "register modules" do
    assert ExDNS.Zone.Registry.register([:mod1, :mod2])
    assert ExDNS.Zone.Registry.get_all == [:mod1, :mod2]
    ExDNS.Zone.Registry.clear
  end
end
