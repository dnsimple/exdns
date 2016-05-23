defmodule Exdns.ZoneLoader do
  @moduledoc """
  Logic for loading zone data from a source.

  Currently only loading from the filesystem is supported.
  """

  require Logger

  def load_zones do
    binary = Exdns.Config.zone_file |> File.read!
    Logger.info("Parsing zones JSON from #{Exdns.Config.zone_file}")

    {:ok, json_zones} = JSX.decode(binary)
    Logger.info("Putting zones into cache")

    Enum.each(json_zones, fn(json_zone) ->
      zone = Exdns.ZoneParser.json_to_zone(json_zone)
      Exdns.ZoneCache.put_zone(zone.name, zone)
    end)
    Logger.info("Loaded #{length(json_zones)} zones")
    {:ok, length(json_zones)}
  end
end
