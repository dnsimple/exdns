defmodule Exdns.ConfigTest do
  use ExUnit.Case, async: true

  test "catch exceptions" do
    assert !Exdns.Config.catch_exceptions?
    Application.put_env(:exdns, :catch_exceptions, true)
    assert Exdns.Config.catch_exceptions?
    Application.put_env(:exdns, :catch_exceptions, false)
  end

  test "use root hints" do
    assert !Exdns.Config.use_root_hints?
    Application.put_env(:exdns, :use_root_hints, true)
    assert Exdns.Config.use_root_hints?
    Application.put_env(:exdns, :use_root_hints, false)
  end

  test "provides zone file path" do
    assert Exdns.Config.zone_file == "priv/test.zones.json"
  end

  test "storage type" do
    assert Exdns.Config.storage_type == Exdns.Storage.EtsStorage
  end

  test "get port" do
    assert Exdns.Config.get_port == 8053
  end

  test "get address for IPv4" do
    assert Exdns.Config.get_address(:inet) == {127, 0, 0, 1}
  end

  test "get address for IPv6" do
    assert Exdns.Config.get_address(:inet6) == {0, 0, 0, 0, 0, 0, 0, 1}
  end

  test "get number of workers" do
    assert Exdns.Config.get_num_workers == 16
  end
end
