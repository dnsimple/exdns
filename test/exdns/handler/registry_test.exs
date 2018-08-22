defmodule Exdns.Handler.RegistryTest do
  use ExUnit.Case, async: true

  @handler_module Exdns.Handler.RegistryTest.DummyHandler

  defmodule DummyHandler do
  end

  test "register handler" do
    record_types = [:dns_terms_const.dns_type_a()]
    assert Exdns.Handler.Registry.register_handler(record_types, @handler_module)
    Exdns.Handler.Registry.clear()
  end

  test "get handlers" do
    assert [] = Exdns.Handler.Registry.get_handlers()
  end

  test "register and get handler" do
    record_types = [:dns_terms_const.dns_type_a()]
    module = @handler_module
    Exdns.Handler.Registry.register_handler(record_types, @handler_module)

    assert [{^module, ^record_types}] = Exdns.Handler.Registry.get_handlers()
    Exdns.Handler.Registry.clear()
  end
end
