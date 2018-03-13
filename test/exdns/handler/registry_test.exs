defmodule ExDNS.Handler.RegistryTest do
  use ExUnit.Case, async: true

  @handler_module ExDNS.Handler.RegistryTest.DummyHandler

  defmodule DummyHandler do
  end

  test "register handler" do
    record_types = [:dns_terms_const.dns_type_a()]
    assert ExDNS.Handler.Registry.register_handler(record_types, @handler_module)
    ExDNS.Handler.Registry.clear() 
  end

  test "get handlers" do
    assert [] = ExDNS.Handler.Registry.get_handlers()
  end

  test "register and get handler" do
    record_types = [:dns_terms_const.dns_type_a()]
    module = @handler_module
    ExDNS.Handler.Registry.register_handler(record_types, @handler_module)

    assert [{^module, ^record_types}] = ExDNS.Handler.Registry.get_handlers()
    ExDNS.Handler.Registry.clear() 
  end
end

