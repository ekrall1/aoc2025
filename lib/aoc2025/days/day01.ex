defmodule Aoc2025.Days.Day01 do
  @moduledoc """
  Advent of Code 2025 - Day 1
  """

  @behaviour Aoc2025.Day

  @start_position 50
  @num_positions 100

  @typedoc "Direction of movement"
  @type direction :: :left | :right

  @typedoc "A movement - direction and spaces"
  @type move :: {direction(), non_neg_integer()}

  @typedoc "Position on the dial"
  @type position :: non_neg_integer()

  @spec part1(String.t()) :: String.t()
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
    {_, zeros} = p1_reduce(lst, @start_position, @num_positions)

    Integer.to_string(zeros)
  end

  @spec part2(String.t()) :: String.t()
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
    {_, zeros} = p2_reduce(lst, @start_position, @num_positions)

    Integer.to_string(zeros)
  end

  defp parse_input(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.map(fn <<hd::binary-size(1), rest::binary>> ->
      dir =
        case hd do
          "R" -> :right
          _ -> :left
        end

      {dir, String.to_integer(rest)}
    end)
  end

  defp p1_reduce(lst, start, nums) do
    Enum.reduce(lst, {start, 0}, fn {dir, spaces}, {position, zeros} ->
      new_pos =
        case dir do
          :right -> Integer.mod(position + spaces, nums)
          :left -> Integer.mod(position - spaces, nums)
        end

      new_zeros = if new_pos == 0, do: zeros + 1, else: zeros
      {new_pos, new_zeros}
    end)
  end

  defp p2_reduce(lst, start, nums) do
    Enum.reduce(lst, {start, 0}, fn {dir, spaces}, {position, zeros} ->
      move =
        case dir do
          :right -> spaces
          :left -> -spaces
        end

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
