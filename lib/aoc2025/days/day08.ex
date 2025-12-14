defmodule Aoc2025.Days.Day08 do
  @moduledoc """
  Advent of Code 2025 - Day 8
  """

  @behaviour Aoc2025.Day

  @type point3 :: {integer(), integer(), integer()}
  @type idx :: non_neg_integer()
  @type pair_key :: {idx(), idx()}
  @type dist_map :: %{optional(pair_key()) => float()}
  @type best_entry :: {non_neg_integer(), pair_key()}

  @spec part1(String.t()) :: String.t()
  @doc """
  Solves part 1 of day 8.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day08.txt")
      iex> Aoc2025.Days.Day08.part1(test_input)
      "40"

  """
  @impl Aoc2025.Day
  def part1(input) do
    points = parse_points(input)

    num =
      if length(points) <= 20 do
        10
      else
        1000
      end

    edges = shortest_pairs(points, num)

    dsu =
      edges
      |> Enum.reduce(dsu_new(length(points)), fn {_d2, {i, j}}, dsu ->
        {_merged?, dsu2} = dsu_union(dsu, i, j)
        dsu2
      end)

    top3 =
      dsu
      |> dsu_circuit_sizes(length(points))
      |> Enum.take(3)

    Enum.reduce(top3, 1, fn c, acc ->
      acc * c
    end)
    |> Integer.to_string()
  end

  @doc """
  Solves part 2 of day 8.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day08.txt")
      iex> Aoc2025.Days.Day08.part2(test_input)
      "Day 8 Part 2 not implemented yet"

  """
  @impl Aoc2025.Day
  def part2(_input) do
    # TODO: Implement Day 8 Part 2
    # input is the raw file content as a string
    "Day 8 Part 2 not implemented yet"
  end

  @spec parse_points(String.t()) :: [point3()]
  def parse_points(text) do
    text
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn line ->
      [xs, ys, zs] =
        line
        |> String.split(",", trim: true)

      {parse_int!(xs), parse_int!(ys), parse_int!(zs)}
    end)
  end

  @spec parse_int!(String.t()) :: integer()
  def parse_int!(s) do
    s = s |> String.trim()
    String.to_integer(s)
  end

  @spec euclidean(point3(), point3()) :: non_neg_integer()
  def euclidean({x1, y1, z1}, {x2, y2, z2}) do
    dx = x2 - x1
    dy = y2 - y1
    dz = z2 - z1
    dx * dx + dy * dy + dz * dz
  end

  @spec shortest_pairs([point3()], non_neg_integer()) :: [best_entry()]
  def shortest_pairs(points, num) do
    indexed = Enum.with_index(points)

    Enum.reduce(indexed, [], fn {p1, i}, best ->
      Enum.reduce(indexed, best, fn {p2, j}, best2 ->
        if j > i do
          d2 = euclidean(p1, p2)
          insert_best(best2, {d2, {i, j}}, num)
        else
          best2
        end
      end)
    end)
  end

  @spec insert_best([best_entry()], best_entry(), pos_integer()) :: [best_entry()]
  defp insert_best(best, entry = {_d2, _pair}, k) do
    best2 =
      [entry | best]
      |> Enum.sort_by(fn {euclidean, _} -> euclidean end)
      |> Enum.take(k)

    best2
  end

  @type dsu :: %{parent: %{idx() => idx()}, size: %{idx() => pos_integer()}}

  @spec dsu_new(non_neg_integer()) :: dsu()
  defp dsu_new(n) do
    parent = for i <- 0..(n - 1), into: %{}, do: {i, i}
    size = for i <- 0..(n - 1), into: %{}, do: {i, 1}
    %{parent: parent, size: size}
  end

  @spec dsu_find(dsu(), idx()) :: idx()
  defp dsu_find(dsu, x) do
    p = dsu.parent[x]
    if p == x, do: x, else: dsu_find(dsu, p)
  end

  @spec dsu_union(dsu(), idx(), idx()) :: {boolean(), dsu()}
  defp dsu_union(dsu, a, b) do
    ra = dsu_find(dsu, a)
    rb = dsu_find(dsu, b)

    if ra == rb do
      {false, dsu}
    else
      sa = dsu.size[ra]
      sb = dsu.size[rb]

      if sa >= sb do
        dsu2 =
          dsu
          |> put_in([:parent, rb], ra)
          |> put_in([:size, ra], sa + sb)

        {true, dsu2}
      else
        dsu2 =
          dsu
          |> put_in([:parent, ra], rb)
          |> put_in([:size, rb], sa + sb)

        {true, dsu2}
      end
    end
  end

  @spec dsu_circuit_sizes(dsu(), non_neg_integer()) :: [pos_integer()]
  defp dsu_circuit_sizes(dsu, n) do
    Enum.reduce(0..(n - 1), %{}, fn i, acc ->
      r = dsu_find(dsu, i)
      Map.update(acc, r, 1, &(&1 + 1))
    end)
    |> Map.values()
    |> Enum.sort(:desc)
  end
end
