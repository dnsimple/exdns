use Mix.Config

config :exdns, port: 8053
config :exdns, catch_exceptions: false
config :exdns, zone_file: "priv/test.zones.json"

config :exdns, servers: [
  %{name: :udp_inet_localhost_1, type: Exdns.Server.UdpServer, address: "127.0.0.1", port: 8053, family: :inet, processes: 2},
  %{name: :udp_inet6_localhost_1, type: Exdns.Server.UdpServer, address: "::1", port: 8053, family: :inet6},
  %{name: :tcp_inet_localhost_1, type: Exdns.Server.TcpServer, address: "127.0.0.1", port: 8053, family: :inet, processes: 2},
  %{name: :tcp_inet6_localhost_1, type: Exdns.Server.TcpServer, address: "::1", port: 8053, family: :inet6}
]
