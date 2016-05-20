defmodule Exdns.ConfigTest do
  use ExUnit.Case, async: true

  test "use root hints" do
    assert Exdns.Config.use_root_hints() == false
  end

  test "storage type" do
    assert Exdns.Config.storage_type() == Exdns.Storage.EtsStorage
  end

  test "get port" do
    assert Exdns.Config.get_port() == 8053
  end

  test "get address for IPv4" do
    assert Exdns.Config.get_address(:inet) == {127, 0, 0, 1}
  end

  test "get number of workers" do
    assert Exdns.Config.get_num_workers() == 16
  end
end
