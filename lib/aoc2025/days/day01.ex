defmodule Aoc2025.Days.Day01 do
  @moduledoc """
  Advent of Code 2025 - Day 1
  """

  @behaviour Aoc2025.Day

  @doc """
  Solves part 1 of day 1.

  ## Examples

     iex> input = File.read!("tests/test_input/day01.txt")
     iex> Aoc2025.Days.Day01.part1(input)
     "3"
  """
  @impl Aoc2025.Day
  def part1(input) do
    lst = parse_input(input)
    {_, zeros} = p1_reduce(lst, 50, 100)

    Integer.to_string(zeros)
  end

  @spec part2(any()) :: <<_::256>>
  @doc """
  Solves part 2 of day 1.

  ## Examples

     iex> input = File.read!("tests/test_input/day01.txt")
     iex> Aoc2025.Days.Day01.part2(input)
     "6"
  """
  @impl Aoc2025.Day
  def part2(input) do
    lst = parse_input(input)
    {_, zeros} = p2_reduce(lst, 50, 100)

    Integer.to_string(zeros)
  end

  defp parse_input(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.map(fn <<hd::binary-size(1), rest::binary>> ->
      {hd, String.to_integer(rest)}
    end)
  end

  defp p1_reduce(lst, start, nums) do
    Enum.reduce(lst, {start, 0}, fn {dir, spaces}, {position, zeros} ->
      position =
        if dir == "R",
          do: Integer.mod(position + spaces, nums),
          else: Integer.mod(position - spaces, nums)

      zeros = if position == 0, do: zeros + 1, else: zeros
      {position, zeros}
    end)
  end

  defp p2_reduce(lst, start, nums) do
    Enum.reduce(lst, {start, 0}, fn {dir, spaces}, {position, zeros} ->
      move = if dir == "R", do: spaces, else: -spaces

      crossings = get_p2_crossings(position, move, nums)

      position = Integer.mod(position + move, nums)
      {position, zeros + crossings}
    end)
  end

  defp get_p2_crossings(position, move, nums) do
    cond do
      move > 0 ->
        div(position + move, nums)

      move < 0 ->
        d = -move

        cond do
          d < position -> 0
          position == 0 -> div(d, nums)
          true -> div(d + nums - position, nums)
        end

      true ->
        0
    end
  end
end
