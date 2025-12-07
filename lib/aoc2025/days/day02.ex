defmodule Aoc2025.Days.Day02 do
  @moduledoc """
  Advent of Code 2025 - Day 02
  """

  @behaviour Aoc2025.Day

  @typedoc "single invalid Id count"
  @type id_count :: non_neg_integer()

  @typedoc "string key for hashmap"
  @type num_id :: non_neg_integer()

  @typedoc "hashmap of invalid ids to count of that id"
  @type invalid_hm :: %{num_id() => id_count()}

  @typedoc "start of id range"
  @type id_start :: non_neg_integer()

  @typedoc "end of id range"
  @type id_end :: non_neg_integer()

  @typedoc "id range"
  @type id_range :: {id_start(), id_end()}

  @spec part1(String.t()) :: String.t()
  @doc """
  Solves part 1 of day 02.

  ## Examples

      iex> input = File.read!("tests/test_input/day02.txt")
      iex> Aoc2025.Days.Day02.part1(input)
      "1227775554"

  """
  @impl Aoc2025.Day
  def part1(input) do
    parse_input(input)
    |> collect_invalid()
    |> Enum.reduce(0, fn {key, _}, acc ->
      acc + key
    end)
    |> Integer.to_string()
  end

  @spec part2(String.t()) :: String.t()
  @doc """
  Solves part 2 of day 02.

  ## Examples

      iex> input = File.read!("tests/test_input/day02.txt")
      iex> Aoc2025.Days.Day02.part2(input)
      "4174379265"

  """
  @impl Aoc2025.Day
  def part2(input) do
    parse_input(input)
    |> collect_invalid_p2()
    |> Enum.reduce(0, fn {key, _}, acc ->
      acc + key
    end)
    |> Integer.to_string()
  end

  @spec parse_input(String.t()) :: [id_range()]
  defp parse_input(input) do
    input
    |> String.split(",", trim: true)
    |> Enum.map(fn elem ->
      bounds = elem |> String.trim() |> String.split("-")
      {String.to_integer(List.first(bounds)), String.to_integer(List.last(bounds))}
    end)
  end

  @spec is_invalid(integer()) :: boolean()
  defp is_invalid(idx) do
    sidx = Integer.to_string(idx)
    len = String.length(sidx)

    case Integer.mod(len, 2) do
      0 ->
        mid = div(len, 2)
        String.slice(sidx, 0, mid) == String.slice(sidx, mid, mid)

      _ ->
        false
    end
  end

  @spec collect_invalid([id_range()]) :: invalid_hm()
  defp collect_invalid(input) do
    Enum.reduce(input, %{}, fn {start_id, end_id}, invalid_ids_hm ->
      Enum.reduce(start_id..end_id, invalid_ids_hm, fn idx, acc ->
        if is_invalid(idx) do
          Map.update(acc, idx, 1, &(&1 + 1))
        else
          acc
        end
      end)
    end)
  end

  @spec collect_invalid_p2([id_range()]) :: invalid_hm()
  defp collect_invalid_p2(input) do
    Enum.reduce(input, %{}, fn {start_id, end_id}, invalid_ids_hm ->
      Enum.reduce(start_id..end_id, invalid_ids_hm, fn idx, acc ->
        sidx = Integer.to_string(idx)
        shifted = get_shifted(sidx)

        if String.contains?(shifted, sidx) do
          Map.update(acc, idx, 1, &(&1 + 1))
        else
          acc
        end
      end)
    end)
  end

  @spec get_shifted(String.t()) :: String.t()
  defp get_shifted(sidx) do
    expanded = sidx <> sidx
    String.slice(expanded, 1, String.length(expanded) - 2)
  end
end
