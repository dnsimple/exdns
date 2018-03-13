defmodule ExDNS.ConfigTest do
  use ExUnit.Case, async: true

  test "catch exceptions" do
    assert !ExDNS.Config.catch_exceptions?
    Application.put_env(:ex_dns, :catch_exceptions, true)
    assert ExDNS.Config.catch_exceptions?
    Application.put_env(:ex_dns, :catch_exceptions, false)
  end

  test "use root hints" do
    assert !ExDNS.Config.use_root_hints?
    Application.put_env(:ex_dns, :use_root_hints, true)
    assert ExDNS.Config.use_root_hints?
    Application.put_env(:ex_dns, :use_root_hints, false)
  end

  test "provides zone file path" do
    assert ExDNS.Config.zone_file == "priv/test.zones.json"
  end

  test "storage type" do
    assert ExDNS.Config.storage_type == ExDNS.Storage.EtsStorage
  end

  test "number of workers" do
    assert ExDNS.Config.num_workers == 16
  end

  test "servers" do
    assert ExDNS.Config.servers == []
  end

  test "wildcard fallback" do
    assert !ExDNS.Config.wildcard_fallback?
  end
end
