defmodule Exdns.Constants do
  @moduledoc """
  Use this module will import definitions from 'dns/include/dns.hrl'
  """
  defmacro __using__(_opts) do
    quote do
      require Quaff
      Quaff.include_lib("dns_erlang/include/dns.hrl")
    end
  end
end
