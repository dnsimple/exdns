defmodule ExDNS.Edns do
  @moduledoc """
  EDNS0 support (extensions for DNS)
  """

  require Record
  require ExDNS.Records

  def get_opts(message), do: get_opts(ExDNS.Records.dns_message(message, :additional), [])

  def get_opts([], opts), do: opts
  def get_opts([rr|rest], opts) do
    case rr do
      ^rr when Record.is_record(rr, :dns_rr) ->
        get_opts(rest, opts)
      ^rr when Record.is_record(rr, :dns_optrr) ->
        if ExDNS.Records.dns_optrr(rr, :dnssec) do
          get_opts(rest, opts ++ [{:dnssec, true}])
        else
          get_opts(rest, opts)
        end
      _ ->
        get_opts(rest, opts)
    end
  end

end
