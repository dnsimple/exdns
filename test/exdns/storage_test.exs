defmodule ExDNS.StorageTest do
  use ExUnit.Case, async: false

  test "create" do
    assert ExDNS.Storage.create(:test) == :ok
  end

  test "insert" do
    ExDNS.Storage.create(:test)
    assert ExDNS.Storage.insert(:test, {:key, :value})
    assert :ets.lookup(:test, :key) == [key: :value]
  end

  test "delete table" do
    ExDNS.Storage.create(:test)
    assert ExDNS.Storage.delete_table(:test) == :ok
  end

  test "delete key from table" do
    ExDNS.Storage.create(:test)
    assert ExDNS.Storage.delete(:test, :key) == :ok
    ExDNS.Storage.insert(:test, {:key, :value})
    assert ExDNS.Storage.select(:test, :key) == [key: :value]
    assert ExDNS.Storage.delete(:test, :key) == :ok
    assert ExDNS.Storage.select(:test, :key) == []
  end

  test "backup table not implemented" do
    assert ExDNS.Storage.backup_table(:test) == {:error, :not_implemented}
  end

  test "backup tables not implemented" do
    assert ExDNS.Storage.backup_tables() == {:error, :not_implemented}
  end

  test "select key from table" do
    ExDNS.Storage.create(:test)
    assert ExDNS.Storage.select(:test, :key) == []
    ExDNS.Storage.insert(:test, {:key, :value})
    assert ExDNS.Storage.select(:test, :key) == [key: :value]
  end

  test "select match spec from table" do
    ExDNS.Storage.create(:test)
    assert ExDNS.Storage.select(:test, [{{:"$1", :"$2"}, [], [{{:"$1", :"$2"}}]}], :infinite) == []
    ExDNS.Storage.insert(:test, {:key, :value})
    assert ExDNS.Storage.select(:test, :key) == [key: :value]
  end

  test "foldl on table" do
    ExDNS.Storage.create(:test)
    ExDNS.Storage.insert(:test, {:key1, 1})
    ExDNS.Storage.insert(:test, {:key2, 1})
    assert ExDNS.Storage.foldl(fn({_key, val}, acc) -> val + acc end, 0, :test) == 2
  end

  test "empty table" do
    ExDNS.Storage.create(:test)
    ExDNS.Storage.insert(:test, {:key, :value})
    assert ExDNS.Storage.select(:test, :key) == [key: :value]
    ExDNS.Storage.empty_table(:test)
    assert ExDNS.Storage.select(:test, :key) == []
  end

  test "list table" do
    ExDNS.Storage.create(:test)
    ExDNS.Storage.insert(:test, {:key, :value})
    assert ExDNS.Storage.list_table(:test) == [key: :value]
  end
end


