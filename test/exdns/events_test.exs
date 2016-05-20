defmodule Exdns.EventsTest do
  require Logger

  defmodule EventCapture do
    use GenEvent

    def init(_) do
      {:ok, []}
    end

    def handle_event(message, messages) do
      {:ok, [message|messages]}
    end

    def handle_call(:messages, messages) do
      {:ok, Enum.reverse(messages), messages}
    end
  end

  use ExUnit.Case

  test "start the event manager" do
    Exdns.Events.start_link()
  end

  test "add handler and notify" do
    Exdns.Events.add_handler(Exdns.EventsTest.EventCapture, [])
    Exdns.Events.notify(:test)
    assert GenEvent.call(Exdns.Events, Exdns.EventsTest.EventCapture, :messages) == [:test]
  end

  test "handle start_severs event" do
    Exdns.Server.Supervisor.stop()
    Exdns.Events.add_handler(Exdns.Events, [])
    assert GenEvent.call(Exdns.Events, Exdns.Events, :get_servers_running) == false
    Exdns.Events.notify(:start_servers)
    assert GenEvent.call(Exdns.Events, Exdns.Events, :get_servers_running) == true
  end
end
