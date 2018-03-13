defmodule ExDNSTest do
  use ExUnit.Case
  doctest ExDNS

  test "greets the world" do
    assert ExDNS.hello() == :world
  end
end
