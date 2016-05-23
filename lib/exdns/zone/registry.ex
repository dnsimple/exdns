defmodule Exdns.Zone.Registry do
  @moduledoc """
  Registry for custom zone parsers. 
  """

  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: Exdns.Zone.Registry)
  end

  def register(modules) do
    GenServer.call(Exdns.Zone.Registry, {:register, modules})
  end

  def get_all do
    GenServer.call(Exdns.Zone.Registry, :get_all)
  end

  def clear do
    GenServer.call(Exdns.Zone.Registry, :clear)
  end

  ## Server callbacks

  def init([]) do
    {:ok, []}
  end

  def handle_call({:register, modules}, _, items) do
    {:reply, :ok, items ++ List.flatten([modules])}
  end

  def handle_call(:get_all, _, items) do
    {:reply, items, items}
  end

  def handle_call(:clear, _, items) do
    {:reply, :ok, []}
  end
end


