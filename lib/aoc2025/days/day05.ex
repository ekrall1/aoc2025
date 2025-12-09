defmodule Aoc2025.Days.Day05 do
  @moduledoc """
  Advent of Code 2025 - Day 05
  """

  @behaviour Aoc2025.Day

  @type ingredient_ranges :: [{non_neg_integer(), non_neg_integer()}]

  @type ingredients :: [non_neg_integer()]

  @type input_obj :: %{ranges: ingredient_ranges(), ingredients: ingredients()}

  @spec part1(String.t()) :: String.t()
  @doc """
  Solves part 1 of day 05.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day05.txt")
      iex> Aoc2025.Days.Day05.part1(test_input)
      "3"

  """
  @impl Aoc2025.Day
  def part1(input) do
    input_obj =
      input
      |> parse_input

    input_obj.ingredients
    |> Enum.reduce(0, fn n, acc ->
      acc + count_spoiled(n, input_obj.ranges)
    end)
    |> Integer.to_string()
  end

  @spec part2(String.t()) :: String.t()
  @doc """
  Solves part 2 of day 05.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day05.txt")
      iex> Aoc2025.Days.Day05.part2(test_input)
      "14"

  """
  @impl Aoc2025.Day
  def part2(input) do
    input_obj =
      input
      |> parse_input

    merge_ranges(input_obj.ranges)
    |> Enum.reduce(0, fn {x, y}, acc -> acc + y - x + 1 end)
    |> Integer.to_string()
  end

  @spec parse_input(String.t()) :: input_obj()
  defp parse_input(input) do
    parts = input |> String.split("\n\n")
    ingredient_ranges = get_ingredient_ranges(List.first(parts))
    ingredients = get_ingredients(List.last(parts))
    %{ranges: ingredient_ranges, ingredients: ingredients}
  end

  @spec get_ingredient_ranges(String.t()) :: ingredient_ranges()
  defp get_ingredient_ranges(range_input) do
    range_input
    |> String.split("\n", trim: true)
    |> Enum.map(&String.split(&1, "-"))
    |> Enum.map(fn [a, b] -> {String.to_integer(a), String.to_integer(b)} end)
  end

  @spec get_ingredients(String.t()) :: ingredients()
  defp get_ingredients(ingredient_input) do
    ingredient_input
    |> String.split("\n", trim: true)
    |> Enum.map(fn a -> String.to_integer(a) end)
  end

  defp count_spoiled(_, []), do: 0

  defp count_spoiled(ingredient, [{x, y} | tl]) do
    case ingredient >= x and ingredient <= y do
      true -> 1
      false -> count_spoiled(ingredient, tl)
    end
  end

  @spec merge_ranges(ingredient_ranges()) :: ingredient_ranges()
  defp merge_ranges(ranges) do
    ranges
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.reduce([], fn {s, e}, acc ->
      case acc do
        [] ->
          [{s, e}]

        [{cur_s, cur_e} | rest] ->
          if s <= cur_e + 1 do
            [{cur_s, max(cur_e, e)} | rest]
          else
            [{s, e} | acc]
          end
      end
    end)
  end
end
