use Mix.Config

config :logger, level: :info

config :ex_dns, catch_exceptions: false
config :ex_dns, zone_file: "priv/test.zones.json"
