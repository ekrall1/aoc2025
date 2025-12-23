defmodule Aoc2025.Days.Day12 do
  @moduledoc """
  Advent of Code 2025 - Day 12
  """

  @behaviour Aoc2025.Day

  @type shape_id :: non_neg_integer()
  @type coord :: {non_neg_integer(), non_neg_integer()}
  @type shape_grid :: [String.t()]
  @type shape :: %{id: shape_id(), grid: shape_grid(), cells: MapSet.t(coord())}
  @type region :: %{
          w: non_neg_integer(),
          h: non_neg_integer(),
          counts: [non_neg_integer()]
        }

  @type parsed :: %{shapes: %{shape_id() => shape()}, regions: [region()]}

  @spec part1(String.t()) :: String.t()
  @doc """
  Solves part 1 of day 12.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day12.txt")
      iex> Aoc2025.Days.Day12.part1(test_input)
      "Day 12 Part 1 not implemented yet"

  """
  @impl Aoc2025.Day
  def part1(input) do
    _ = parse_input(input)
    "Day 12 Part 1 not implemented yet"
  end

  @spec part2(String.t()) :: String.t()
  @doc """
  Solves part 2 of day 12.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day12.txt")
      iex> Aoc2025.Days.Day12.part2(test_input)
      "Day 12 Part 2 not implemented yet"

  """
  @impl Aoc2025.Day
  def part2(_input) do
    # TODO: Implement Day 12 Part 2
    # input is the raw file content as a string
    "Day 12 Part 2 not implemented yet"
  end

  @spec parse_input(String.t()) :: parsed()
  defp parse_input(input) do
    lines = input |> String.split("\n", trim: false)
    {shape_lines, region_lines} = split_sections(lines)

    shapes = shape_lines |> parse_shapes() |> Map.new(fn s -> {s.id, s} end)
    regions = parse_regions(region_lines)

    %{shapes: shapes, regions: regions}
  end

  @spec split_sections([String.t()]) :: {[String.t()], [String.t()]}
  defp split_sections(lines) do
    {a, b} = Enum.split_while(lines, fn ln -> not String.match?(ln, ~r/^\d+x\d+:\s*/) end)
    {Enum.reject(a, &blank?/1), Enum.reject(b, &blank?/1)}
  end

  @spec blank?(String.t()) :: boolean()
  defp blank?(s), do: String.trim(s) == ""

  @spec parse_shapes([String.t()]) :: [shape()]
  defp parse_shapes(lines) do
    lines
    |> chunk_by_shape()
    |> Enum.map(&parse_shape_block/1)
  end

  @spec chunk_by_shape([String.t()]) :: [[String.t()]]
  defp chunk_by_shape(lines) do
    {blocks, cur} =
      Enum.reduce(lines, {[], []}, fn ln, {acc, cur} ->
        if String.match?(ln, ~r/^\d+:\s*$/), do: {acc ++ [cur], [ln]}, else: {acc, cur ++ [ln]}
      end)

    (blocks ++ [cur]) |> Enum.reject(&(&1 == []))
  end

  @spec parse_shape_block([String.t()]) :: shape()
  defp parse_shape_block([hdr | grid]) do
    id = hdr |> String.trim_trailing(":") |> String.to_integer()
    g = Enum.map(grid, &String.trim/1)
    %{id: id, grid: g, cells: grid_to_cells(g)}
  end

  @spec grid_to_cells(shape_grid()) :: MapSet.t(coord())
  defp grid_to_cells(grid) do
    grid
    |> Enum.with_index()
    |> Enum.reduce(MapSet.new(), fn {row, y}, acc -> add_row_cells(acc, row, y) end)
  end

  @spec add_row_cells(MapSet.t(coord()), String.t(), non_neg_integer()) :: MapSet.t(coord())
  defp add_row_cells(acc, row, y) do
    row
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.reduce(acc, fn
      {"#", x}, a -> MapSet.put(a, {x, y})
      {".", _x}, a -> a
    end)
  end

  @spec parse_regions([String.t()]) :: [region()]
  defp parse_regions(lines), do: Enum.map(lines, &parse_region_line/1)

  @spec parse_region_line(String.t()) :: region()
  defp parse_region_line(line) do
    [lhs, rhs] = String.split(line, ~r/\s*:\s*/, parts: 2)
    {w, h} = parse_dims(lhs)
    %{w: w, h: h, counts: parse_counts(rhs)}
  end

  @spec parse_dims(String.t()) :: {non_neg_integer(), non_neg_integer()}
  defp parse_dims(s) do
    [w, h] = s |> String.trim() |> String.split("x", parts: 2)
    {String.to_integer(w), String.to_integer(h)}
  end

  @spec parse_counts(String.t()) :: [non_neg_integer()]
  defp parse_counts(s) do
    s
    |> String.split(~r/\s+/, trim: true)
    |> Enum.map(&String.to_integer/1)
  end
end
