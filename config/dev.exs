use Mix.Config

config :ex_dns, catch_exceptions: false
config :ex_dns, zone_file: "priv/test.zones.json"

config :ex_dns, servers: [
  %{name: :udp_inet_localhost_1, type: ExDNS.Server.UDPServer, address: "127.0.0.1", port: 8053, family: :inet},
  %{name: :udp_inet6_localhost_1, type: ExDNS.Server.UDPServer, address: "::1", port: 8053, family: :inet6},
  %{name: :tcp_inet_localhost_1, type: ExDNS.Server.TCPServer, address: "127.0.0.1", port: 8053, family: :inet},
  %{name: :tcp_inet6_localhost_1, type: ExDNS.Server.TCPServer, address: "::1", port: 8053, family: :inet6}
]
