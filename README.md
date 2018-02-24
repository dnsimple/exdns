# Exdns

[![Build Status](https://api.travis-ci.org/dnsimple/exdns.svg?branch=master)](https://travis-ci.org/dnsimple/exdns/)

A port of erldns (https://github.com/aetrion/erl-dns) to Elixir.

*NOTE*: This application is in the very early stages of development. It passes all of the tests currently defined in https://github.com/dnsimple/dnstest however it is not on parity with erl-dns functionality yet.

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

Install dependencies with `mix deps.get`

Run with `mix run --no-halt`

Note that to run in production you will need to set up a production configuration
and add one or more servers to it.

```
config :exdns, servers: [
  %{name: :udp_inet_localhost_1, type: Exdns.Server.UdpServer, address: "127.0.0.1", port: 8053, family: :inet},
  %{name: :udp_inet6_localhost_1, type: Exdns.Server.UdpServer, address: "::1", port: 8053, family: :inet6},
  %{name: :tcp_inet_localhost_1, type: Exdns.Server.TcpServer, address: "127.0.0.1", port: 8053, family: :inet},
  %{name: :tcp_inet6_localhost_1, type: Exdns.Server.TcpServer, address: "::1", port: 8053, family: :inet6}
]
```
