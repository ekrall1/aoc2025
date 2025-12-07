defmodule Aoc2025.Days.Day03 do
  @moduledoc """
  Advent of Code 2025 - Day 03
  """

  @behaviour Aoc2025.Day

  @typedoc "overall max int value"
  @type overall_max :: non_neg_integer()

  @typedoc "row"
  @type row :: String.t()

  @typedoc "row length"
  @type row_len :: non_neg_integer()

  @typedoc "row slice"
  @type row_slice :: String.t()

  @typedoc "index of first digit"
  @type idx_1 :: non_neg_integer()

  @typedoc "index of snd digit"
  @type idx_2 :: non_neg_integer()

  @typedoc "remaining row max index"
  @type rem_max_idx :: non_neg_integer()

  @spec part1(String.t()) :: String.t()
  @doc """
  Solves part 1 of day 03.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day03.txt")
      iex> Aoc2025.Days.Day03.part1(test_input)
      "357"

  """
  @impl Aoc2025.Day
  def part1(input) do
    rows = parse_input(input)

    sumrows =
      Enum.reduce(rows, 0, fn row, max_num ->
        max_num + process_row(row)
      end)

    Integer.to_string(sumrows)
  end

  @doc """
  Solves part 2 of day 03.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day03.txt")
      iex> Aoc2025.Days.Day03.part2(test_input)
      "Day 03 Part 2 not implemented yet"

  """
  @impl Aoc2025.Day
  def part2(_input) do
    # TODO: Implement Day 03 Part 2
    # input is the raw file content as a string
    "Day 03 Part 2 not implemented yet"
  end

  @spec parse_input(String.t()) :: [row()]
  defp parse_input(input) do
    input
    |> String.split("\n", trim: true)
  end

  @spec process_row(row()) :: overall_max()
  defp process_row(row) do
    len = get_row_len(row)

    0..(len - 2)
    |> Enum.reduce(0, fn idx1, max_num ->
      (idx1 + 1)..(len - 1)
      |> Enum.reduce(max_num, fn idx2, max_num2 ->
        row_slice = String.slice(row, idx2..(len - 1))
        snd_digit_idx = get_rem_max_idx(row_slice) + idx2
        update_max(row, idx1, snd_digit_idx, max_num2)
      end)
    end)
  end

  @spec get_row_len(row() | row_slice()) :: row_len()
  defp get_row_len(row) do
    String.length(row)
  end

  @spec get_rem_max_idx(row_slice()) :: rem_max_idx()
  defp get_rem_max_idx(row_part) do
    digits =
      row_part
      |> String.graphemes()
      |> Enum.map(&String.to_integer/1)

    max = Enum.max(digits)
    Enum.find_index(digits, fn x -> x == max end)
  end

  @spec update_max(row(), idx_1(), idx_2(), overall_max()) :: overall_max()
  defp update_max(row, idx1, idx2, overall_max) do
    new_num_string = String.at(row, idx1) <> String.at(row, idx2)
    new_int = String.to_integer(new_num_string)

    case new_int > overall_max do
      true -> new_int
      _ -> overall_max
    end
  end
end
