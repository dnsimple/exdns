defmodule ExDNS.Handler.Registry do
  @moduledoc """
  Registry for custom handlers. 
  """

  use GenServer
  require Logger

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def register_handler(record_types, module) do
    GenServer.call(__MODULE__, {:register_handler, record_types, module})
  end

  def get_handlers do
    GenServer.call(__MODULE__, {:get_handlers})
  end

  def clear do
    GenServer.call(__MODULE__, :clear)
  end

  ## Server callbacks

  def init([]) do
    Logger.info(IO.ANSI.green <> "Starting the Registry" <> IO.ANSI.reset())
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

