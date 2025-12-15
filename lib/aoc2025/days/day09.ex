defmodule Aoc2025.Days.Day09 do
  @moduledoc """
  Advent of Code 2025 - Day 9
  """

  @behaviour Aoc2025.Day

  @type point :: {integer(), integer()}
  @type result :: {point(), point(), non_neg_integer()}
  @type max_area_points :: [point()]

  @spec part1(String.t()) :: String.t()
  @doc """
  Solves part 1 of day 9.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day09.txt")
      iex> Aoc2025.Days.Day09.part1(test_input)
      "50"

  """
  @impl Aoc2025.Day
  def part1(input) do
    input
    |> parse_input()
    |> max_area_rect()
    |> then(fn {_, _, area} -> Integer.to_string(area) end)
  end

  @doc """
  Solves part 2 of day 9.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day09.txt")
      iex> Aoc2025.Days.Day09.part2(test_input)
      "Day 9 Part 2 not implemented yet"

  """
  @impl Aoc2025.Day
  def part2(_input) do
    # TODO: Implement Day 9 Part 2
    # input is the raw file content as a string
    "Day 9 Part 2 not implemented yet"
  end

  @spec parse_input(String.t()) :: [point()]
  defp parse_input(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn line ->
      [x, y] =
        line
        |> String.split(",", parts: 2, trim: true)

      {String.to_integer(x), String.to_integer(y)}
    end)
  end

  @spec max_area_rect([point()]) :: result() | nil

  defp max_area_rect([]), do: nil
  defp max_area_rect([_]), do: nil

  defp max_area_rect(points) do
    {best_pair, best_area} =
      Enum.reduce(Enum.with_index(points), {{nil, nil}, 0}, fn {p1, i}, {bp, ba} ->
        Enum.reduce(Enum.drop(points, i + 1), {bp, ba}, fn p2, {bp2, ba2} ->
          {x1, y1} = p1
          {x2, y2} = p2
          area = abs(x1 - x2 + 1) * abs(y1 - y2 + 1)

          if area > ba2, do: {{p1, p2}, area}, else: {bp2, ba2}
        end)
      end)

    {p1, p2} = best_pair
    {p1, p2, best_area}
  end
end
