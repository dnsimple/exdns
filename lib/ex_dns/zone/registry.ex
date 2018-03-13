defmodule ExDNS.Zone.Registry do
  @moduledoc """
  Registry for custom zone parsers. 
  """

  use GenServer
  require Logger

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: ExDNS.Zone.Registry)
  end

  def register(modules) do
    GenServer.call(ExDNS.Zone.Registry, {:register, modules})
  end

  def get_all do
    GenServer.call(ExDNS.Zone.Registry, :get_all)
  end

  def clear do
    GenServer.call(ExDNS.Zone.Registry, :clear)
  end

  ## Server callbacks

  def init([]) do
    Logger.info(IO.ANSI.green <> "Starting the Zone Registry" <> IO.ANSI.reset())
    {:ok, []}
  end

  def handle_call({:register, modules}, _, items) do
    {:reply, :ok, items ++ List.flatten([modules])}
  end

  def handle_call(:get_all, _, items) do
    {:reply, items, items}
  end

  def handle_call(:clear, _, _items) do
    {:reply, :ok, []}
  end
end


