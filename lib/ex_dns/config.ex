defmodule ExDNS.Config do
  @moduledoc """
  Configuration details for exdns.
  """

  def catch_exceptions?, do: Application.get_env(:exdns, :catch_exceptions, true)

  def use_root_hints?, do: Application.get_env(:exdns, :use_root_hints, false)

  def zone_file, do: Application.get_env(:exdns, :zone_file, "zones.json")

  def storage_type, do: Application.get_env(:exdns, :storage_type, ExDNS.Storage.EtsStorage)

  def num_workers, do: Application.get_env(:exdns, :num_workers, 16)

  def servers, do: Application.get_env(:exdns, :servers, [])

  def wildcard_fallback?, do: Application.get_env(:exdns, :wildcard_fallback, false)

end
