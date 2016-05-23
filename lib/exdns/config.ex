defmodule Exdns.Config do
  @moduledoc """
  Configuration details for exdns.
  """

  def catch_exceptions?, do: Application.get_env(:exdns, :catch_exceptions, true)

  def use_root_hints?, do: Application.get_env(:exdns, :use_root_hints, false)

  def zone_file, do: Application.get_env(:exdns, :zone_file, "zones.json")

  def storage_type, do: Application.get_env(:exdns, :storage_type, Exdns.Storage.EtsStorage)

  def get_port, do: Application.get_env(:exdns, :port, 53)

  def get_num_workers, do: Application.get_env(:exdns, :num_workers, 16)

  def get_address(:inet), do: {127, 0, 0, 1}
  def get_address(:inet6), do: {0, 0, 0, 0, 0, 0, 0, 1}

  def get_servers, do: []
end
