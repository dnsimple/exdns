use Mix.Config

config :exdns, catch_exceptions: false
config :exdns, zone_file: "priv/test.zones.json"
config :exdns, use_root_hints: true

config :exdns,
  servers: [
    %{
      name: :udp_inet_localhost_1,
      type: Exdns.Server.UdpServer,
      address: "127.0.0.1",
      port: 8053,
      family: :inet
    },
    # %{name: :udp_inet6_localhost_1, type: Exdns.Server.UdpServer, address: "::1", port: 8053, family: :inet6},
    %{
      name: :tcp_inet_localhost_1,
      type: Exdns.Server.TcpServer,
      address: "127.0.0.1",
      port: 8053,
      family: :inet
    }
    # %{name: :tcp_inet6_localhost_1, type: Exdns.Server.TcpServer, address: "::1", port: 8053, family: :inet6}
  ]
