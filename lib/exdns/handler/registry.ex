defmodule Exdns.Handler.Registry do
  @moduledoc """
  Handler registry
  """

  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: Exdns.Handler.Registry)
  end

  def register_handler(record_types, module) do
    GenServer.call(Exdns.Handler.Registry, {:register_handler, record_types, module})
  end

  def get_handlers() do
    GenServer.call(Exdns.Handler.Registry, {:get_handlers})
  end

  def clear() do
    GenServer.call(Exdns.Handler.Registry, :clear)
  end

  ## Server callbacks

  def init([]) do
    {:ok, []}
  end

  def handle_call({:register_handler, record_types, module}, _, handlers) do
    {:reply, :ok, handlers ++ [{module, record_types}]}
  end

  def handle_call({:get_handlers}, _, handlers) do
    {:reply, handlers, handlers}
  end

  def handle_call(:clear, _, handlers) do
    {:reply, :ok, []}
  end
end

