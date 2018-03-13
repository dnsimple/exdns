defmodule ExDNS.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_dns,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExDNS.Application, []},
      start_phases: [{:post_start, []}]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:earmark, "~> 1.2"},
      {:ex_doc, "~> 0.18"},
      {:dns_erlang, git: "https://github.com/aetrion/dns_erlang.git", app: false},
      {:folsom, "~> 0.8"},
      {:jason, "~> 1.0"}
    ]
  end

  defp description do
    """
    ExDNS is an authoritative name server. It is ported from erldns and adapted to the Elixir language.
    """
  end

  defp package do
    [
      name: :ex_dns,
      maintainers: ["Anthony Eden"],
      licenses: ["MIT License"],
      links: %{
        "GitHub" => "https://github.com/dnsimple/exdns",
        "Documentation" => "https://hexdocs.pm/exdns/0.0.2"
      }
    ]
  end
end
