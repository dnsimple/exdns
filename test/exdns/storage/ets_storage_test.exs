defmodule Exdns.Storage.EtsStorageTest do
  use ExUnit.Case, async: false

  test "create" do
    assert Exdns.Storage.EtsStorage.create(:test) == :ok
  end

  test "create lookup table" do
    assert Exdns.Storage.EtsStorage.create(:lookup_table) == :ok
  end

  test "create schema is not implemented" do
    assert Exdns.Storage.EtsStorage.create(:schema) == {:error, :not_implemented}
  end

  test "insert" do
    Exdns.Storage.EtsStorage.create(:test)
    assert Exdns.Storage.EtsStorage.insert(:test, {:key, :value})
    assert :ets.lookup(:test, :key) == [key: :value]
  end

  test "delete table" do
    Exdns.Storage.EtsStorage.create(:test)
    assert Exdns.Storage.EtsStorage.delete_table(:test) == :ok
  end

  test "backup table not implemented" do
    assert Exdns.Storage.EtsStorage.backup_table(:test) == {:error, :not_implemented}
  end

  test "backup tables not implemented" do
    assert Exdns.Storage.EtsStorage.backup_tables() == {:error, :not_implemented}
  end

  test "select key from table" do
    Exdns.Storage.EtsStorage.create(:test)
    assert Exdns.Storage.EtsStorage.select(:test, :key) == []
    Exdns.Storage.EtsStorage.insert(:test, {:key, :value})
    assert Exdns.Storage.EtsStorage.select(:test, :key) == [key: :value]
  end

  test "select match spec from table" do
    Exdns.Storage.EtsStorage.create(:test)
    assert Exdns.Storage.EtsStorage.select(:test, [{{'$1', '$2'}, [], [{{'$1', '$2'}}]}], :infinite) == []
    Exdns.Storage.EtsStorage.insert(:test, {:key, :value})
    assert Exdns.Storage.EtsStorage.select(:test, :key) == [key: :value]
  end

  test "foldl on table" do
    Exdns.Storage.EtsStorage.create(:test)
    Exdns.Storage.EtsStorage.insert(:test, {:key1, 1})
    Exdns.Storage.EtsStorage.insert(:test, {:key2, 1})
    assert Exdns.Storage.EtsStorage.foldl(fn({_key, val}, acc) -> val + acc end, 0, :test) == 2
  end

  test "empty table" do
    Exdns.Storage.EtsStorage.create(:test)
    Exdns.Storage.EtsStorage.insert(:test, {:key, :value})
    assert Exdns.Storage.EtsStorage.select(:test, :key) == [key: :value]
    Exdns.Storage.EtsStorage.empty_table(:test)
    assert Exdns.Storage.EtsStorage.select(:test, :key) == []
  end

  test "list table" do
    Exdns.Storage.EtsStorage.create(:test)
    Exdns.Storage.EtsStorage.insert(:test, {:key, :value})
    assert Exdns.Storage.EtsStorage.list_table(:test) == [key: :value]
  end
end

