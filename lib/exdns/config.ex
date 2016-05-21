defmodule Exdns.Config do
  def use_root_hints(), do: Application.get_env(:exdns, :use_root_hints)
  def storage_type(), do: Exdns.Storage.EtsStorage
  def get_port(), do: 8053
  def get_address(:inet), do: {127, 0, 0, 1}
  def get_address(:inet6), do: {0, 0, 0, 0, 0, 0, 0, 1}
  def get_num_workers(), do: 16
  def get_servers(), do: []
end
