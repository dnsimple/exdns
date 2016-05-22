use Mix.Config

config :exdns, port: 8053
config :exdns, catch_exceptions: false
config :exdns, zone_file: "priv/test.zones.json"
