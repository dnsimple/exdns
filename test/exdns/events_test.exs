defmodule ExDNS.EventsTest do
  use ExUnit.Case
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

  test "start the event manager" do
    ExDNS.Events.start_link([])
  end

  test "add handler and notify" do
    ExDNS.Events.add_handler(ExDNS.EventsTest.EventCapture, [])
    ExDNS.Events.notify(:test)
    assert GenEvent.call(ExDNS.Events, ExDNS.EventsTest.EventCapture, :messages) == [:test]
  end

  test "handle start_severs event" do
    ExDNS.Events.add_handler(ExDNS.Events, [])
    assert GenEvent.call(ExDNS.Events, ExDNS.Events, :get_servers_running) == false
    ExDNS.Events.notify(:start_servers)
    assert GenEvent.call(ExDNS.Events, ExDNS.Events, :get_servers_running) == true
  end
end
