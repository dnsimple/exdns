defmodule Exdns.Decoder do
  @moduledoc """
  Functions used to decode DNS messages safely.
  """

  require Logger

  @spec decode_message(:dns.message_bin()) :: {:dns.decode_error(), :dns.message() | :undefined, binary()} | :dns.message()
  def decode_message(bin) do
    if Exdns.Config.catch_exceptions? do
      try do
        :dns.decode_message(bin)
      catch
        e ->
          Logger.error("Error decoding #{inspect bin}: #{e}")
          {:formerr, e, bin}
      end
    else
      :dns.decode_message(bin)
    end
  end
end
