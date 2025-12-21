defmodule Aoc2025.Days.Day10 do
  @moduledoc """
  Advent of Code 2025 - Day 10
  """

  @behaviour Aoc2025.Day

  @type goal :: [non_neg_integer()]

  @type button :: [non_neg_integer()]

  @type wiring :: [button()]

  @type joltage :: MapSet.t(non_neg_integer())

  @type problem_input :: %{goal: goal(), wiring: wiring(), joltage: joltage()}

  @line_re ~r/^\[([.#]+)\]\s*((?:\([0-9,\s]*\)\s*)*)\{([0-9,\s]+)\}\s*$/

  @spec part1(String.t()) :: String.t()
  @doc """
  Solves part 1 of day 10.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day10.txt")
      iex> Aoc2025.Days.Day10.part1(test_input)
      "Day 10 Part 1 not implemented yet"

  """
  @impl Aoc2025.Day
  def part1(input) do
    _ = parse_input(input)
    "part 1 not implemented yet"
  end

  @spec parse_input(String.t()) :: [problem_input()]
  defp parse_input(input) do
    lines = input |> String.split("\n")

    Enum.reduce(lines, [], fn line, acc ->
      parts = Regex.run(@line_re, line)

      [%{
        goal: parse_goal(Enum.at(parts, 1)),
        wiring: parse_wiring(Enum.at(parts, 2)),
        joltage: parse_joltage(Enum.at(parts, 3))
      } | acc]
    end)
  end

  @spec parse_goal(String.t()) :: goal()
  defp parse_goal(goal_s) do
    goal_s
    |> String.replace(".", "0")
    |> String.replace("#", "1")
    |> String.graphemes()
    |> Enum.map(&String.to_integer/1)
  end

  @spec parse_wiring(String.t()) :: wiring()
  defp parse_wiring(wiring_s) do
    Regex.scan(~r/\((?<inner>[0-9,\s]*)\)/, wiring_s, capture: ["inner"])
    |> Enum.map(fn [inner] ->
      inner
      |> String.trim()
      |> case do
        "" ->
          []
        s ->
          s
          |> String.split(",", trim: true)
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.to_integer/1)
      end
    end)
  end

  @spec parse_joltage(String.t()) :: joltage()
  defp parse_joltage(joltage_s) do
    joltage_s
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_integer/1)
    |> MapSet.new()
  end

  @doc """
  Solves part 2 of day 10.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day10.txt")
      iex> Aoc2025.Days.Day10.part2(test_input)
      "Day 10 Part 2 not implemented yet"

  """
  @impl Aoc2025.Day
  def part2(_input) do
    # TODO: Implement Day 10 Part 2
    # input is the raw file content as a string
    "Day 10 Part 2 not implemented yet"
  end

  # Helper functions can go here
  # defp parse_input(input) do
  #   input
  #   |> String.trim()
  #   |> String.split("\n")
  # end
end
