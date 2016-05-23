defmodule Exdns.Encoder do
  @moduledoc """
  Functions for encoding DNS messages to binary representations safely.
  """

  require Logger
  require Exdns.Records

  def encode_message(message) do
    encode_message(message, [])
  end

  @spec encode_message(:dns.message(), [:dns.encode_message_opt()]) ::
    {false, :dns.message_bin()} |
    {true, :dns.message_bin(), :dns.message()} |
    {false, :dns.message_bin(), :dns.tsig_mac()} |
    {true, :dns.message_bin(), :dns.tsig_mac(), :dns.message()}
  def encode_message(message, opts) do
    if Exdns.Config.catch_exceptions? do
      try do
        :dns.encode_message(message, opts)
      catch
        e ->
          Logger.error("Error encoding #{inspect message} (#{e})")
          encode_message(build_error_message(message))
      end
    else
      :dns.encode_message(message, opts)
    end
  end

  # Private functions

  defp build_error_message({_, message}), do: build_error_message(message, :dns_term_const.dns_rcode_servfail)
  defp build_error_message(message), do: build_error_message(message, :dns_term_const.dns_rcode_servfail)
  defp build_error_message(message, rcode), do: Exdns.Records.dns_message(rc: rcode)
end
