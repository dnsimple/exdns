defmodule Exdns.EventsTest do
  use ExUnit.Case
  require Logger

  defmodule EventCapture do
    use GenServer

    def init(_) do
      {:ok, []}
    end

    def handle_cast(message, messages) do
      {:noreply, [message | messages]}
    end

    def handle_call(:messages, _from, messages) do
      {:reply, Enum.reverse(messages), messages}
    end
  end

  test "start the event manager" do
    Exdns.Events.start_link()
  end

  test "add handler and notify" do
    {:ok, pid} = Exdns.Events.add_handler(Exdns.EventsTest.EventCapture, [])
    Exdns.Events.notify(:test)
    assert GenServer.call(pid, :messages) == [:test]
  end
end
