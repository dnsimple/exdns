defmodule ExDNS.Zone.Loader do
  @moduledoc """
  Logic for loading zone data from a source.

  Currently only loading from the filesystem is supported.
  """

  require Logger

  def load_zones do
    binary = ExDNS.Config.zone_file |> File.read!
    Logger.info("Parsing zones JSON from #{ExDNS.Config.zone_file}")

    {:ok, json_zones} = JSX.decode(binary)
    Logger.info("Putting zones into cache")

    Enum.each(json_zones, fn(json_zone) ->
      zone = ExDNS.Zone.Parser.json_to_zone(json_zone)
      ExDNS.Zone.Cache.put_zone(zone.name, zone)
    end)
    Logger.info("Loaded #{length(json_zones)} zones")
    {:ok, length(json_zones)}
  end
end
