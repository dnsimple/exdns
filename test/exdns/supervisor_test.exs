defmodule Exdns.SupervisorTest do
  use ExUnit.Case, async: true

  test "starts the events worker" do
    assert List.keymember?(Supervisor.which_children(Exdns.Supervisor), Exdns.Events, 0)
  end

  test "starts the packet cache" do
    assert List.keymember?(Supervisor.which_children(Exdns.Supervisor), Exdns.PacketCache, 0)
  end

  test "starts the query throttle" do
    assert List.keymember?(Supervisor.which_children(Exdns.Supervisor), Exdns.QueryThrottle, 0)
  end

  test "starts the handler registry" do
    assert List.keymember?(Supervisor.which_children(Exdns.Supervisor), Exdns.Handler.Registry, 0)
  end
end
