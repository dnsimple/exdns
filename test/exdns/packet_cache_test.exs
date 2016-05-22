defmodule Exdns.PacketCacheTest do
  use ExUnit.Case, async: false
  require Exdns.Records

  test "get question not in cache" do
    assert Exdns.PacketCache.clear()
    question = Exdns.Records.dns_query()
    assert Exdns.PacketCache.get(question) == {:error, :cache_miss}
  end

  test "get question in cache" do
    question = Exdns.Records.dns_query()
    message = Exdns.Records.dns_message()
    assert Exdns.PacketCache.put(question, message)
    assert Exdns.PacketCache.get(question) == {:ok, message}
    assert Exdns.PacketCache.get(question, {1, 2, 3, 4}) == {:ok, message}
  end

  test "get question in cache that is expired" do
    question = Exdns.Records.dns_query()
    message = Exdns.Records.dns_message()
    assert Exdns.Storage.insert(:packet_cache, {question, {message, 0}})
    assert Exdns.PacketCache.get(question) == {:error, :cache_expired}
  end

  test "sweep the cache" do
    question = Exdns.Records.dns_query()
    message = Exdns.Records.dns_message()
    assert Exdns.Storage.insert(:packet_cache, {question, {message, 0}})
    assert Exdns.PacketCache.get(question) == {:error, :cache_expired}
    Exdns.PacketCache.sweep()
    assert Exdns.PacketCache.get(question) == {:error, :cache_miss}
  end

  test "clear the cache" do
    question = Exdns.Records.dns_query()
    message = Exdns.Records.dns_message()
    assert Exdns.PacketCache.put(question, message)
    assert Exdns.PacketCache.get(question) == {:ok, message}
    assert Exdns.PacketCache.clear
    assert Exdns.PacketCache.get(question) == {:error, :cache_miss}
  end
end
