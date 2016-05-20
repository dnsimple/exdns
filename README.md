# Exdns

A port of erldns (https://github.com/aetrion/erl-dns) to Elixir.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add exdns to your list of dependencies in `mix.exs`:

        def deps do
          [{:exdns, "~> 0.0.1"}]
        end

  2. Ensure exdns is started before your application:

        def application do
          [applications: [:exdns]]
        end

## Running locally

Run with `mix run --no-halt`

