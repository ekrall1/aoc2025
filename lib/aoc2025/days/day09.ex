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
      "24"

  """
  @impl Aoc2025.Day
  def part2(input) do
    red = parse_input(input)

    case max_valid_rect_area(red) do
      0 -> "0"
      area -> Integer.to_string(area)
    end
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

  @spec max_valid_rect_area([point()]) :: non_neg_integer()
  defp max_valid_rect_area(points) when length(points) < 2, do: 0

  defp max_valid_rect_area(points) do
    {min_y, max_y} = minmax_by(points, fn {_x, y} -> y end)
    vertical_edges = build_vertical_edges(points)
    horizontal_edges = build_horizontal_edges(points)

    intervals_by_y =
      for y <- min_y..max_y, into: %{} do
        {y, allowed_intervals_for_row(y, vertical_edges, horizontal_edges)}
      end

    indexed = Enum.with_index(points)

    {best_area, _best_pair} =
      Enum.reduce(indexed, {0, nil}, fn {p1, i}, {best_area, best_pair} ->
        Enum.reduce(indexed, {best_area, best_pair}, fn {p2, j}, {ba, bp} ->
          if j <= i do
            {ba, bp}
          else
            {x1, y1} = p1
            {x2, y2} = p2

            if x1 == x2 or y1 == y2 do
              {ba, bp}
            else
              xmin = min(x1, x2)
              xmax = max(x1, x2)
              ymin = min(y1, y2)
              ymax = max(y1, y2)

              area = (xmax - xmin + 1) * (ymax - ymin + 1)

              # Prune by current best
              if area <= ba do
                {ba, bp}
              else
                if rect_inside?(xmin, xmax, ymin, ymax, intervals_by_y) do
                  # IO.write(Integer.to_string(elem(p1, 0)) <> "," <> Integer.to_string(elem(p1, 1)) <> " " <> Integer.to_string(elem(p2, 0)) <> "," <> Integer.to_string(elem(p2, 1)) <> "\n")
                  {area, {p1, p2}}
                else
                  {ba, bp}
                end
              end
            end
          end
        end)
      end)

    best_area
  end

  @spec build_vertical_edges([point()]) :: [{integer(), integer(), integer()}]
  defp build_vertical_edges(points) do
    cyclic = points ++ [hd(points)]

    cyclic
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.flat_map(fn [{x1, y1}, {x2, y2}] ->
      cond do
        x1 == x2 and y1 != y2 ->
          [{x1, min(y1, y2), max(y1, y2)}]

        true ->
          []
      end
    end)
  end

  @spec build_horizontal_edges([point()]) :: [{integer(), integer(), integer()}]
  defp build_horizontal_edges(points) do
    cyclic = points ++ [hd(points)]

    cyclic
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.flat_map(fn [{x1, y1}, {x2, y2}] ->
      cond do
        y1 == y2 and x1 != x2 ->
          [{y1, min(x1, x2), max(x1, x2)}]

        true ->
          []
      end
    end)
  end

  @spec merge_intervals([{integer(), integer()}]) :: [{integer(), integer()}]
  defp merge_intervals(intervals) do
    intervals
    |> Enum.sort()
    |> Enum.reduce([], fn {a, b}, acc ->
      case acc do
        [] ->
          [{a, b}]

        [{p, q} | rest] ->
          if q >= a do
            [{p, max(q, b)} | rest]
          else
            [{a, b} | acc]
          end
      end
    end)
    |> Enum.reverse()
  end

  @spec allowed_intervals_for_row(
          integer(),
          [{integer(), integer(), integer()}],
          [{integer(), integer(), integer()}]
        ) :: [{integer(), integer()}]
  defp allowed_intervals_for_row(y, vertical_edges, horizontal_edges) do
    yq = y + 0.5

    xs =
      vertical_edges
      |> Enum.flat_map(fn {x, y_lo, y_hi} ->
        if yq > y_lo and yq < y_hi, do: [x], else: []
      end)
      |> Enum.sort()

    interior =
      xs
      |> Enum.chunk_every(2)
      |> Enum.map(fn [a, b] -> {min(a, b), max(a, b)} end)

    boundary =
      horizontal_edges
      |> Enum.flat_map(fn {yy, x_lo, x_hi} ->
        if yy == y, do: [{x_lo, x_hi}], else: []
      end)

    merge_intervals(interior ++ boundary)
  end

  @spec rect_inside?(integer(), integer(), integer(), integer(), %{
          integer() => [{integer(), integer()}]
        }) ::
          boolean()
  defp rect_inside?(xmin, xmax, ymin, ymax, intervals_by_y) do
    Enum.all?(ymin..ymax, fn y ->
      intervals = Map.get(intervals_by_y, y, [])
      Enum.any?(intervals, fn {a, b} -> a <= xmin and b >= xmax end)
    end)
  end

  @spec minmax_by([point()], (point() -> integer())) :: {integer(), integer()}
  defp minmax_by([h | t], f) do
    v0 = f.(h)

    Enum.reduce(t, {v0, v0}, fn p, {mn, mx} ->
      v = f.(p)
      {min(mn, v), max(mx, v)}
    end)
  end
end
