defmodule Exdns.Mixfile do
  use Mix.Project

  def project do
    [app: :exdns,
     version: "0.0.2",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :folsom], mod: {Exdns, []}, start_phases: [{:post_start, []}]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:folsom, "~> 0.8.7"},
      {:exjsx, "~> 3.2.0"},
      {:dns_erlang, git: "https://github.com/aetrion/dns_erlang.git", app: false},
      {:quaff, github: "jeanparpaillon/quaff"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    """
    exdns is an authoritative name server. It is ported from erldns and adapted to the Elixir language.
    """
  end

  defp package do
    [
      name: :exdns,
      maintainers: ["Anthony Eden"],
      licenses: ["MIT License"],
      links: %{
        "GitHub" => "https://github.com/dnsimple/exdns",
        "Documentation" => "https://hexdocs.pm/exdns/0.0.2"
      }
    ]
  end
end
