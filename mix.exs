defmodule ExDNS.MixProject do
  use Mix.Project

  def project do
    [
      app: :exdns,
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
      {:dns_erlang, git: "https://github.com/aetrion/dns_erlang.git", app: false},
      {:earmark, "~> 1.2"},
      {:ex_doc, "~> 0.18"},
      {:exjsx, "~> 4.0.0"},
      {:folsom, "~> 0.8"},
    ]
  end

  defp description do
    """
    ExDNS is an authoritative name server. It is ported from erldns and adapted to the Elixir language.
    """
  end

  defp package do
    [
      name: :exdns,
      maintainers: ["Anthony Eden"],
      licenses: ["MIT License"],
      links: %{
        "GitHub" => "https://github.com/dnsimple/exdns",
      }
    ]
  end
end
