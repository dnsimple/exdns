use Mix.Config

config :logger, level: :info

config :exdns, catch_exceptions: false
config :exdns, zone_file: "priv/test.zones.json"
