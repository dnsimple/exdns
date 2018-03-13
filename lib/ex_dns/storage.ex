defmodule ExDNS.Storage do
  @moduledoc """
  Interface for storage engines.
  """

  # Public API

  def create(table) do
    mod().create(table)
  end

  def insert(table, value) do
    mod().insert(table, value)
  end

  def delete_table(table) do
    mod().delete_table(table)
  end

  def delete(table, key) do
    mod().delete(table, key)
  end

  def backup_table(_table) do
    {:error, :not_implemented}
  end

  def backup_tables() do
    {:error, :not_implemented}
  end

  def select(table, key) do
    mod().select(table, key)
  end

  def select(table, match_spec, limit) do
    mod().select(table, match_spec, limit)
  end

  def foldl(fun, acc, table) do
    mod().foldl(fun, acc, table)
  end

  def empty_table(table) do
    mod().empty_table(table)
  end

  def list_table(table) do
    mod().list_table(table)
  end

  # Private functions

  defp mod() do
    ExDNS.Config.storage_type()
  end
end
