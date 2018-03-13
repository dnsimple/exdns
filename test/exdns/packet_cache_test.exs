defmodule ExDNS.PacketCacheTest do
  use ExUnit.Case, async: false
  require ExDNS.Records

  test "get question not in cache" do
    assert ExDNS.PacketCache.clear()
    question = ExDNS.Records.dns_query()
    assert ExDNS.PacketCache.get(question) == {:error, :cache_miss}
  end

  test "get question in cache" do
    question = ExDNS.Records.dns_query()
    message = ExDNS.Records.dns_message()
    assert ExDNS.PacketCache.put(question, message)
    assert ExDNS.PacketCache.get(question) == {:ok, message}
    assert ExDNS.PacketCache.get(question, {1, 2, 3, 4}) == {:ok, message}
  end

  test "get question in cache that is expired" do
    question = ExDNS.Records.dns_query()
    message = ExDNS.Records.dns_message()
    assert ExDNS.Storage.insert(:packet_cache, {question, {message, 0}})
    assert ExDNS.PacketCache.get(question) == {:error, :cache_expired}
  end

  test "sweep the cache" do
    question = ExDNS.Records.dns_query()
    message = ExDNS.Records.dns_message()
    assert ExDNS.Storage.insert(:packet_cache, {question, {message, 0}})
    assert ExDNS.PacketCache.get(question) == {:error, :cache_expired}
    ExDNS.PacketCache.sweep()
    assert ExDNS.PacketCache.get(question) == {:error, :cache_miss}
  end

  test "clear the cache" do
    question = ExDNS.Records.dns_query()
    message = ExDNS.Records.dns_message()
    assert ExDNS.PacketCache.put(question, message)
    assert ExDNS.PacketCache.get(question) == {:ok, message}
    assert ExDNS.PacketCache.clear
    assert ExDNS.PacketCache.get(question) == {:error, :cache_miss}
  end
end
