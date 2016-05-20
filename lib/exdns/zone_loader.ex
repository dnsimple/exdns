defmodule Exdns.ZoneLoader do
  require Logger

  @filename "zones.json"

  def load_zones() do
    binary = File.read!(filename)
    Logger.info("Parsing zones JSON")

    {:ok, json_zones} = JSX.decode(binary)
    Logger.info("Putting zones into cache")

    Enum.each(json_zones, fn(json_zone) ->
      zone = Exdns.ZoneParser.json_to_zone(json_zone)
      Exdns.ZoneCache.put_zone(zone.name, zone)
    end)
    Logger.info("Loaded #{length(json_zones)} zones")
    {:ok, length(json_zones)}
  end

  defp filename() do
    case Application.get_env(:exdns, :zones) do
      {:ok, filename} -> filename
      _ -> @filename
    end
  end
end
