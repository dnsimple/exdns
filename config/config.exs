# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :exdns, catch_exceptions: true

import_config "#{Mix.env}.exs"
