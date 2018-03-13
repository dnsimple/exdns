defmodule ExDNS.Handler.Registry do
  @moduledoc """
  Registry for custom handlers. 
  """

  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: ExDNS.Handler.Registry)
  end

  def register_handler(record_types, module) do
    GenServer.call(ExDNS.Handler.Registry, {:register_handler, record_types, module})
  end

  def get_handlers do
    GenServer.call(ExDNS.Handler.Registry, {:get_handlers})
  end

  def clear do
    GenServer.call(ExDNS.Handler.Registry, :clear)
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

  def handle_call(:clear, _, _handlers) do
    {:reply, :ok, []}
  end
end

