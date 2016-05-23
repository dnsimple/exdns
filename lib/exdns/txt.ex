defmodule Exdns.Txt do
  @moduledoc """
  Functions for parsing TXT record content.
  """

  require Logger

  @max_txt_size 255

  def parse(v) when is_binary(v), do: List.flatten(parse(to_char_list(v)))

  def parse([]), do: []
  def parse([c|rest]), do: parse_char([c|rest], c, rest, [], false)

  def parse(string, [], [], _), do: split(string)
  def parse(_, [], tokens, _), do: tokens
  def parse(string, [c|rest], tokens, escaped), do: parse_char(string, c, rest, tokens, escaped)

  def parse(_, [], tokens, current_token, true), do: tokens ++ [current_token] # Last character is escaped
  def parse(string, [c|rest], tokens, current_token, escaped), do: parse_char(string, c, rest, tokens, current_token, escaped)

  defp parse_char(string, ?", [], tokens, _), do: parse(string, [], tokens, false)
  defp parse_char(string, ?", rest, tokens, _), do: parse(string, rest, tokens, [], false)
  defp parse_char(string, _, rest, tokens, _), do: parse(string, rest, tokens, false)

  defp parse_char(string, ?", rest, tokens, current_token, false), do: parse(string, rest, tokens ++ [split(current_token)], false)
  defp parse_char(string, ?", rest, tokens, current_token, true), do: parse(string, rest, tokens, current_token ++ [?"], false)
  defp parse_char(string, ?\\, rest, tokens, current_token, false), do: parse(string, rest, tokens, current_token, true)
  defp parse_char(string, ?\\, rest, tokens, current_token, true), do: parse(string, rest, tokens, current_token ++ [?\\], false)
  defp parse_char(string, c, rest, tokens, current_token, _), do: parse(string, rest, tokens, current_token ++ [c], false)


  defp split(data), do: split(data, [])

  defp split(data, parts) do
    if byte_size(List.to_string(data)) > @max_txt_size do
      {first, rest} = String.split_at(List.to_string(data), @max_txt_size)
      case rest do
        "" -> parts ++ [[first]]
        _ -> split(to_char_list(rest), parts ++ [first])
      end
    else
      parts ++ [List.to_string(data)]
    end
  end
end
