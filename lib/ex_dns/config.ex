defmodule ExDNS.Config do
  @moduledoc """
  Configuration details for exdns.
  """

  def catch_exceptions?, do: Application.get_env(:ex_dns, :catch_exceptions, true)

  def use_root_hints?, do: Application.get_env(:ex_dns, :use_root_hints, false)

  def zone_file, do: Application.get_env(:ex_dns, :zone_file, "zones.json")

  def storage_type, do: Application.get_env(:ex_dns, :storage_type, ExDNS.Storage.EtsStorage)

  def num_workers, do: Application.get_env(:ex_dns, :num_workers, 16)

  def servers, do: Application.get_env(:ex_dns, :servers, [])

  def wildcard_fallback?, do: Application.get_env(:ex_dns, :wildcard_fallback, false)

end
