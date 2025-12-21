defmodule Aoc2025.Days.Day11 do
  @moduledoc """
  Advent of Code 2025 - Day 11
  """

  @behaviour Aoc2025.Day

  @type graph_node :: String.t()
  @type graph :: %{node() => MapSet.t(graph_node())}

  @spec part1(String.t()) :: String.t()
  @doc """
  Solves part 1 of day 11.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day11.txt")
      iex> Aoc2025.Days.Day11.part1(test_input)
      "Day 11 Part 1 not implemented yet"

  """
  @impl Aoc2025.Day
  def part1(input) do
    _ = parse_input(input)
    "Day 11 Part 1 not implemented yet"
  end

  @spec part2(String.t()) :: String.t()
  @doc """
  Solves part 2 of day 11.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day11.txt")
      iex> Aoc2025.Days.Day11.part2(test_input)
      "Day 11 Part 2 not implemented yet"

  """
  @impl Aoc2025.Day
  def part2(_input) do
    # TODO: Implement Day 11 Part 2
    # input is the raw file content as a string
    "Day 11 Part 2 not implemented yet"
  end

  @spec parse_input(String.t()) :: graph()
  defp parse_input(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.reduce(%{}, fn line, g ->
      {src, nbrs} = parse_line(line)
      Map.put(g, src, MapSet.new(nbrs))
    end)
  end

  @spec parse_line(String.t()) :: {node(), [node()]}
  defp parse_line(line) do
    [lhs, rhs] = String.split(line, ~r/\s*:\s*/, parts: 2)

    neighbors =
      rhs
      |> String.split(~r/\s+/, trim: true)

    {lhs, neighbors}
  end
end
