defmodule Exdns.StorageTest do
  use ExUnit.Case, async: false

  test "create" do
    assert Exdns.Storage.create(:test) == :ok
  end

  test "insert" do
    Exdns.Storage.create(:test)
    assert Exdns.Storage.insert(:test, {:key, :value})
    assert :ets.lookup(:test, :key) == [key: :value]
  end

  test "delete table" do
    Exdns.Storage.create(:test)
    assert Exdns.Storage.delete_table(:test) == :ok
  end

  test "delete key from table" do
    Exdns.Storage.create(:test)
    assert Exdns.Storage.delete(:test, :key) == :ok
    Exdns.Storage.insert(:test, {:key, :value})
    assert Exdns.Storage.select(:test, :key) == [key: :value]
    assert Exdns.Storage.delete(:test, :key) == :ok
    assert Exdns.Storage.select(:test, :key) == []
  end

  test "backup table not implemented" do
    assert Exdns.Storage.backup_table(:test) == {:error, :not_implemented}
  end

  test "backup tables not implemented" do
    assert Exdns.Storage.backup_tables() == {:error, :not_implemented}
  end

  test "select key from table" do
    Exdns.Storage.create(:test)
    assert Exdns.Storage.select(:test, :key) == []
    Exdns.Storage.insert(:test, {:key, :value})
    assert Exdns.Storage.select(:test, :key) == [key: :value]
  end

  test "select match spec from table" do
    Exdns.Storage.create(:test)

    assert Exdns.Storage.select(:test, [{{:"$1", :"$2"}, [], [{{:"$1", :"$2"}}]}], :infinite) ==
             []

    Exdns.Storage.insert(:test, {:key, :value})
    assert Exdns.Storage.select(:test, :key) == [key: :value]
  end

  test "foldl on table" do
    Exdns.Storage.create(:test)
    Exdns.Storage.insert(:test, {:key1, 1})
    Exdns.Storage.insert(:test, {:key2, 1})
    assert Exdns.Storage.foldl(fn {_key, val}, acc -> val + acc end, 0, :test) == 2
  end

  test "empty table" do
    Exdns.Storage.create(:test)
    Exdns.Storage.insert(:test, {:key, :value})
    assert Exdns.Storage.select(:test, :key) == [key: :value]
    Exdns.Storage.empty_table(:test)
    assert Exdns.Storage.select(:test, :key) == []
  end

  test "list table" do
    Exdns.Storage.create(:test)
    Exdns.Storage.insert(:test, {:key, :value})
    assert Exdns.Storage.list_table(:test) == [key: :value]
  end
end
