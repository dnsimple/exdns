defmodule Exdns.Storage.EtsStorage do
  @spec create(atom()) :: :ok | {:error, reason :: term()}
  def create(:schema), do: {:error, :not_implemented}
  def create(name = :lookup_table), do: create_ets_table(name, :bag)
  def create(name), do: create_ets_table(name, :set)

  @spec insert(atom(), tuple()) :: :ok
  def insert(table, value) do
    :ets.insert(table, value)
    :ok
  end

  @spec delete_table(atom()) :: :ok
  def delete_table(table) do
    :ets.delete(table)
    :ok
  end

  def delete(table, key) do
    :ets.delete(table, key)
    :ok
  end

  def backup_table(_table) do
    {:error, :not_implemented}
  end

  def backup_tables() do
    {:error, :not_implemented}
  end

  @spec select(atom(), term()) :: tuple()
  def select(table, key) do
    :ets.lookup(table, key)
  end

  @spec select(atom(), list(), :infinite | integer()) :: tuple() | :ets.'$end_of_table'
  def select(table, match_spec, :infinite) do
    :ets.select(table, match_spec)
  end
  def select(table, match_spec, limit) do
    :ets.select(table, match_spec, limit)
  end

  @spec foldl(fun(), list(), atom()) :: acc :: term()
  def foldl(fun, acc, table) do
    :ets.foldl(fun, acc, table)
  end

  @spec empty_table(atom()) :: :ok
  def empty_table(table) do
    :ets.delete_all_objects(table)
  end

  @spec list_table(atom()) :: term()
  def list_table(table) do
   :ets.tab2list(table)
  end

  # Private functions

  defp create_ets_table(name, type) do
    case :ets.info(name) do
      :undefined ->
        case :ets.new(name, [type, :public, :named_table]) do
          ^name -> :ok
          error -> {:error, error}
        end
      _info_list ->
        :ok
    end
  end
end
