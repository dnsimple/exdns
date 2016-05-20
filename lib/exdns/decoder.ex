defmodule Exdns.Decoder do
  require Logger

  @spec decode_message(:dns.message_bin()) :: {:dns.decode_error(), :dns.message() | :undefined, binary()} | :dns.message()
  def decode_message(bin) do
    case Application.get_env(:erldns, :catch_exceptions) do
      {:ok, false} -> :dns.decode_message(bin)
      _ ->
        try do
          :dns.decode_message(bin)
        catch
          e -> 
            Logger.error("Error decoding #{inspect bin}: #{e}")
            {:formerr, e, bin}
        end
    end
  end
end
