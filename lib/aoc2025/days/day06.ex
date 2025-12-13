defmodule Aoc2025.Days.Day06 do
  @moduledoc """
  Advent of Code 2025 - Day 06
  """

  @behaviour Aoc2025.Day

  @type input_obj :: [[String.t()]]

  @type part2_input_obj :: {[[String.t()]], [String.t()]}

  @spec part1(String.t()) :: String.t()
  @doc """
  Solves part 1 of day 06.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day06.txt")
      iex> Aoc2025.Days.Day06.part1(test_input)
      "4277556"

  """
  @impl Aoc2025.Day
  def part1(input) do
    parse_input(input)
    |> Enum.reduce(0, fn group, acc ->
      acc + get_accumulator(group)
    end)
    |> Integer.to_string()
  end

  @spec part2(String.t()) :: String.t()
  @doc """
  Solves part 2 of day 06.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day06.txt")
      iex> Aoc2025.Days.Day06.part2(test_input)
      "3263827"

  """
  @impl Aoc2025.Day
  def part2(input) do
    {nums, ops} = parse_input2(input)

    Enum.zip(nums, ops)
    |> Enum.reduce(0, fn {group, op}, acc ->
      acc + get_accumulator2(group, op)
    end)
    |> Integer.to_string()
  end

  @spec parse_input(String.t()) :: input_obj()
  defp parse_input(input) do
    transpose =
      input
      |> String.split("\n", trim: true)
      |> Enum.map(fn elem -> String.split(elem, ~r/\s+/, trim: true) end)
      |> Enum.zip()
      |> Enum.map(&Tuple.to_list/1)

    transpose
  end

  @spec parse_input2(String.t()) :: part2_input_obj()
  defp parse_input2(input) do
    instructions =
      input
      |> String.split("\n", trim: true)
      |> Enum.map(&String.graphemes/1)
      |> Enum.reverse()

    nums =
      instructions
      |> tl()
      |> Enum.reverse()
      |> Enum.zip()
      |> Enum.map(fn group -> group |> Tuple.to_list() |> List.to_string() |> String.trim() end)
      |> Enum.join(",")
      |> String.split(",,")
      |> Enum.map(fn group -> group |> String.split(",") end)

    ops =
      instructions
      |> hd()
      |> Enum.reject(&String.match?(&1, ~r/\s/))

    {nums, ops}
  end

  @spec get_accumulator([String.t()]) :: non_neg_integer()
  defp get_accumulator(group) do
    [hd | tl] = Enum.reverse(group)

    case hd do
      "*" -> get_prod(tl)
      _ -> get_sum(tl)
    end
  end

  @spec get_accumulator2([String.t()], String.t()) :: non_neg_integer()
  defp get_accumulator2(group, op) do
    case op do
      "*" -> get_prod(group)
      _ -> get_sum(group)
    end
  end

  @spec get_prod([String.t()]) :: non_neg_integer()
  defp get_prod(group) do
    Enum.reduce(group, 1, fn elem, prod ->
      String.to_integer(elem) * prod
    end)
  end

  @spec get_sum([String.t()]) :: non_neg_integer()
  defp get_sum(group) do
    Enum.reduce(group, 0, fn elem, sum ->
      String.to_integer(elem) + sum
    end)
  end
end
