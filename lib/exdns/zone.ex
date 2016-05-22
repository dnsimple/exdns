defmodule Exdns.Zone do
  defstruct name: :undefined, version: :undefined, authority: :undefined, record_count: 0, records: [], records_by_name: [], records_by_type: []
end
