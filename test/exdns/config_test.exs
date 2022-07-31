defmodule Exdns.ConfigTest do
  use ExUnit.Case, async: true

  test "catch exceptions" do
    assert !Exdns.Config.catch_exceptions?()
    Application.put_env(:exdns, :catch_exceptions, true)
    assert Exdns.Config.catch_exceptions?()
    Application.put_env(:exdns, :catch_exceptions, false)
  end

  test "use root hints" do
    assert !Exdns.Config.use_root_hints?()
    Application.put_env(:exdns, :use_root_hints, true)
    assert Exdns.Config.use_root_hints?()
    Application.put_env(:exdns, :use_root_hints, false)
  end

  test "provides zone file path" do
    assert Exdns.Config.zone_file() == "priv/test.zones.json"
  end

  test "storage type" do
    assert Exdns.Config.storage_type() == Exdns.Storage.EtsStorage
  end

  test "number of workers" do
    assert Exdns.Config.num_workers() == 16
  end

  test "servers" do
    assert Exdns.Config.servers() == []
  end

  test "wildcard fallback" do
    assert !Exdns.Config.wildcard_fallback?()
  end
end
