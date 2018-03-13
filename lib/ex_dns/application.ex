defmodule ExDNS.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    setup_metrics()
    # List all child processes to be supervised
    children = [
      ExDNS.Events,
      ExDNS.Zone.Cache,
      ExDNS.Zone.Registry,
      # ExDNS.ZoneEncoder,
      ExDNS.PacketCache,
      ExDNS.QueryThrottle,
      ExDNS.Handler.Registry
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExDNS.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_phase(:post_start, _start_type, _phase_args) do
    ExDNS.Events.add_handler(ExDNS.Events, [])
    ExDNS.Zone.Loader.load_zones()
    ExDNS.Events.notify(:start_servers)
    :ok
  end

  defp setup_metrics() do
    :folsom_metrics.new_counter(:udp_request_counter)
    :folsom_metrics.new_counter(:tcp_request_counter)
    :folsom_metrics.new_meter(:udp_request_meter)
    :folsom_metrics.new_meter(:tcp_request_meter)
    :folsom_metrics.new_meter(:udp_error_meter)
    :folsom_metrics.new_meter(:tcp_error_meter)
    :folsom_metrics.new_history(:udp_error_history)
    :folsom_metrics.new_history(:tcp_error_history)
    :folsom_metrics.new_meter(:refused_response_meter)
    :folsom_metrics.new_counter(:refused_response_counter)
    :folsom_metrics.new_meter(:empty_response_meter)
    :folsom_metrics.new_counter(:empty_response_counter)
    :folsom_metrics.new_histogram(:udp_handoff_histogram)
    :folsom_metrics.new_histogram(:tcp_handoff_histogram)
    :folsom_metrics.new_counter(:request_throttled_counter)
    :folsom_metrics.new_meter(:request_throttled_meter)
    :folsom_metrics.new_histogram(:request_handled_histogram)
    :folsom_metrics.new_counter(:packet_dropped_empty_queue_counter)
    :folsom_metrics.new_meter(:packet_dropped_empty_queue_meter)
    :folsom_metrics.new_meter(:cache_hit_meter)
    :folsom_metrics.new_meter(:cache_expired_meter)
    :folsom_metrics.new_meter(:cache_miss_meter)

    :folsom_metrics.new_counter(:dnssec_request_counter)
    :folsom_metrics.new_meter(:dnssec_request_meter)
  end
end
