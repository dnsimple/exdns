defmodule ExDNS do
  @moduledoc """
  Documentation for ExDNS.
  """

  def timestamp() do
    {tm, ts, _} = :os.timestamp()
    (tm * 1000000) + ts
  end
end

