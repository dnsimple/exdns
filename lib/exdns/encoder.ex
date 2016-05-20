defmodule Exdns.Encoder do
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
    case Application.get_env(:exdns, :catch_exceptions) do
      {:ok, false} -> :dns.encode_message(message, opts)
      _ ->
        try do
          :dns.encode_message(message, opts)
        catch
          e ->
            Logger.error("Error encoding #{inspect message} (#{e})")
            encode_message(build_error_message(message))
        end
    end
  end

  # Private functions

  defp build_error_message({_, message}) do
    build_error_message(message, :dns_term_const.dns_rcode_servfail)
  end
  defp build_error_message(message) do
    build_error_message(message, :dns_term_const.dns_rcode_servfail)
  end
  defp build_error_message(message, rcode) do
    Exdns.Records.dns_message(rc: rcode)
  end
end
