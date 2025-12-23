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
  @type col_id :: {:cell, non_neg_integer(), non_neg_integer()}
  # {sid, placement_index}
  @type row_id :: {shape_id(), non_neg_integer()}
  # counts left to place
  @type rem_vec :: tuple()
  @type bitset :: tuple()
  @type memo_bits :: MapSet.t({rem_vec(), bitset()})
  @type placed :: {non_neg_integer(), bitset()}
  @type placements_by_sid :: %{shape_id() => [placed()]}

  @spec part1(String.t()) :: String.t()
  @doc """
  Solves part 1 of day 12.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day12.txt")
      iex> Aoc2025.Days.Day12.part1(test_input)
      "2"

  """
  @impl Aoc2025.Day
  def part1(input) do
    parsed = parse_input(input)

    feasible =
      Enum.count(parsed.regions, fn r ->
        IO.write("doing region" <> "\n")
        region_feasible?(parsed.shapes, r)
      end)

    Integer.to_string(feasible)
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

  @spec normalize([{integer(), integer()}]) :: [{non_neg_integer(), non_neg_integer()}]
  defp normalize(pts) do
    shift_to_zero(pts) |> Enum.sort()
  end

  @spec variants(MapSet.t({non_neg_integer(), non_neg_integer()})) :: [
          [{non_neg_integer(), non_neg_integer()}]
        ]
  defp variants(cells) do
    cells |> MapSet.to_list() |> all_transforms() |> Enum.map(&normalize/1) |> Enum.uniq()
  end

  @spec shift_to_zero([{integer(), integer()}]) :: [{integer(), integer()}]
  defp shift_to_zero(pts), do: shift(pts, -min_x(pts), -min_y(pts))

  @spec min_x([{integer(), integer()}]) :: integer()
  defp min_x(pts) do
    pts |> Enum.map(fn {x, _} -> x end) |> Enum.min()
  end

  @spec min_y([{integer(), integer()}]) :: integer()
  defp min_y(pts) do
    pts |> Enum.map(fn {_, y} -> y end) |> Enum.min()
  end

  @spec placements([{integer(), integer()}], {integer(), integer()}) :: [[{integer(), integer()}]]
  defp placements(shape, {w, h}) do
    for x <- 0..(w - 1),
        y <- 0..(h - 1),
        fits?(shape, {x, y}, {w, h}),
        do: Enum.map(shape, fn {sx, sy} -> {sx + x, sy + y} end)
  end

  @spec fits?([{integer(), integer()}], {integer(), integer()}, {integer(), integer()}) ::
          boolean()
  defp fits?(shape, {ox, oy}, {w, h}) do
    Enum.all?(shape, fn {x, y} -> (x + ox) in 0..(w - 1) and (y + oy) in 0..(h - 1) end)
  end

  @spec rot90([{integer(), integer()}]) :: [{integer(), integer()}]
  defp rot90(pts) do
    Enum.map(pts, fn {x, y} -> {y, -x} end)
  end

  @spec flip_x([{integer(), integer()}]) :: [{integer(), integer()}]
  defp flip_x(pts) do
    Enum.map(pts, fn {x, y} -> {-x, y} end)
  end

  @spec all_transforms([{integer(), integer()}]) :: [[{integer(), integer()}]]
  defp all_transforms(pts) do
    r0 = pts
    r1 = rot90(r0)
    r2 = rot90(r1)
    r3 = rot90(r2)
    f0 = flip_x(r0)
    [r0, r1, r2, r3, f0, rot90(f0), rot90(rot90(f0)), rot90(rot90(rot90(f0)))]
  end

  @spec region_feasible?(%{shape_id() => shape()}, region()) :: boolean()
  defp region_feasible?(shapes, %{w: w, h: h, counts: counts}) do
    # Fast prune: required area must match board area
    required_area =
      counts
      |> Enum.with_index()
      |> Enum.reduce(0, fn {c, sid}, acc ->
        if c == 0 do
          acc
        else
          acc + c * MapSet.size(Map.fetch!(shapes, sid).cells)
        end
      end)

    if required_area > w * h do
      false
    else
      rem_vec = rem_from_counts(counts)
      n_words = div(w * h + 63, 64)
      occ0 = empty_bits_tuple(n_words)

      # we only build placements for shapes that actually appear (count > 0)
      sids =
        counts
        |> Enum.with_index()
        |> Enum.filter(fn {c, _sid} -> c > 0 end)
        |> Enum.map(&elem(&1, 1))

      pmap = build_bit_placements(shapes, sids, {w, h}, n_words)

      if Enum.any?(sids, fn sid -> Map.get(pmap, sid, []) == [] end) do
        false
      else
        {res, _memo} = solve_bits(rem_vec, pmap, occ0, MapSet.new(), n_words)
        res == {:ok, true}
      end
    end
  end

  @spec shift([{integer(), integer()}], integer(), integer()) :: [{integer(), integer()}]
  defp shift(pts, dx, dy), do: Enum.map(pts, fn {x, y} -> {x + dx, y + dy} end)

  @spec build_bit_placements(
          %{shape_id() => shape()},
          [shape_id()],
          {non_neg_integer(), non_neg_integer()},
          non_neg_integer()
        ) :: placements_by_sid()
  defp build_bit_placements(shapes, sids, {w, _} = dims, n_words) do
    Enum.reduce(sids, %{}, fn sid, acc ->
      pts = MapSet.to_list(shapes[sid].cells)
      vars = variants(MapSet.new(pts))

      placed =
        vars
        |> Enum.flat_map(&placements(&1, dims))
        |> Enum.map(&cells_to_bits_tuple(&1, w, n_words))
        |> Enum.map(fn bs -> {anchor_word(bs), bs} end)

      Map.put(acc, sid, placed)
    end)
  end

  @spec solve_bits(rem_vec(), placements_by_sid(), bitset(), memo_bits(), non_neg_integer()) ::
          {{:ok, true} | :no_solution, memo_bits()}
  defp solve_bits(rem_vec, pmap, occ, memo, n_words) do
    if rem_done?(rem_vec) do
      {{:ok, true}, memo}
    else
      key = {rem_vec, occ}

      if MapSet.member?(memo, key) do
        {:no_solution, memo}
      else
        {res, memo2} = branch_bits(rem_vec, pmap, occ, memo, n_words)

        if res == :no_solution do
          {res, MapSet.put(memo2, key)}
        else
          {res, memo2}
        end
      end
    end
  end

  @spec branch_bits(rem_vec(), placements_by_sid(), bitset(), memo_bits(), non_neg_integer()) ::
          {{:ok, true} | :no_solution, memo_bits()}
  defp branch_bits(rem_vec, pmap, occ, memo, n_words) do
    sid = choose_sid_bits(rem_vec, pmap, occ)

    placed = Map.fetch!(pmap, sid)
    cands = prefilter(placed, occ)

    if cands == [] do
      {:no_solution, memo}
    else
      try_bits(sid, cands, rem_vec, pmap, occ, memo, n_words)
    end
  end

  @spec count_prefilter_only([placed()], bitset()) :: non_neg_integer()
  defp count_prefilter_only(placed, occ) do
    Enum.reduce(placed, 0, fn {aw, bs}, acc ->
      if Bitwise.band(elem(occ, aw), elem(bs, aw)) == 0, do: acc + 1, else: acc
    end)
  end

  @spec choose_sid_bits(rem_vec(), placements_by_sid(), bitset()) :: shape_id()
  defp choose_sid_bits(rem_vec, pmap, occ) do
    rem_vec
    |> Tuple.to_list()
    |> Enum.with_index()
    |> Enum.filter(fn {c, _sid} -> c > 0 end)
    |> Enum.min_by(fn {_c, sid} ->
      count_prefilter_only(Map.fetch!(pmap, sid), occ)
    end)
    |> elem(1)
  end

  @spec try_bits(
          shape_id(),
          [bitset()],
          rem_vec(),
          placements_by_sid(),
          bitset(),
          memo_bits(),
          non_neg_integer()
        ) :: {{:ok, true} | :no_solution, memo_bits()}
  defp try_bits(_sid, [], _rem_vec, _pmap, _occ, memo, _n_words), do: {:no_solution, memo}

  defp try_bits(sid, [p | ps], rem_vec, pmap, occ, memo, n_words) do
    if overlap_tuple?(occ, p, n_words) do
      try_bits(sid, ps, rem_vec, pmap, occ, memo, n_words)
    else
      rem2 = rem_dec(rem_vec, sid)
      occ2 = bor_tuple(occ, p, n_words)

      {res, memo2} = solve_bits(rem2, pmap, occ2, memo, n_words)

      case res do
        {:ok, true} -> {{:ok, true}, memo2}
        :no_solution -> try_bits(sid, ps, rem_vec, pmap, occ, memo2, n_words)
      end
    end
  end

  @spec anchor_word(bitset()) :: non_neg_integer()
  defp anchor_word(bits) do
    n = tuple_size(bits)

    Enum.find_value(0..(n - 1), 0, fn i ->
      if elem(bits, i) != 0, do: i, else: false
    end)
  end

  @spec prefilter([placed()], bitset()) :: [bitset()]
  defp prefilter(placed, occ) do
    Enum.reduce(placed, [], fn {aw, bs}, acc ->
      if Bitwise.band(elem(occ, aw), elem(bs, aw)) == 0, do: [bs | acc], else: acc
    end)
  end

  @spec rem_from_counts([non_neg_integer()]) :: rem_vec()
  defp rem_from_counts(counts), do: List.to_tuple(counts)

  @spec rem_done?(rem_vec()) :: boolean()
  defp rem_done?(rem_vec), do: Enum.all?(Tuple.to_list(rem_vec), &(&1 == 0))

  @spec rem_dec(rem_vec(), shape_id()) :: rem_vec()
  defp rem_dec(rem_vec, sid) do
    n = elem(rem_vec, sid)
    # assume n > 0
    put_elem(rem_vec, sid, n - 1)
  end

  @spec empty_bits_tuple(non_neg_integer()) :: bitset()
  defp empty_bits_tuple(n_words) do
    List.duplicate(0, n_words) |> List.to_tuple()
  end

  @spec set_bit_tuple(bitset(), non_neg_integer(), non_neg_integer()) :: bitset()
  defp set_bit_tuple(bits, word, bit) do
    wv = elem(bits, word)
    put_elem(bits, word, Bitwise.bor(wv, Bitwise.<<<(1, bit)))
  end

  @spec cells_to_bits_tuple(
          [{non_neg_integer(), non_neg_integer()}],
          non_neg_integer(),
          non_neg_integer()
        ) :: bitset()
  defp cells_to_bits_tuple(cells, w, n_words) do
    Enum.reduce(cells, empty_bits_tuple(n_words), fn {x, y}, bits ->
      id = y * w + x
      word = div(id, 64)
      bit = rem(id, 64)
      set_bit_tuple(bits, word, bit)
    end)
  end

  @spec overlap_tuple?(bitset(), bitset(), non_neg_integer()) :: boolean()
  defp overlap_tuple?(a, b, n_words) do
    Enum.any?(0..(n_words - 1), fn i ->
      Bitwise.band(elem(a, i), elem(b, i)) != 0
    end)
  end

  @spec bor_tuple(bitset(), bitset(), non_neg_integer()) :: bitset()
  defp bor_tuple(a, b, n_words) do
    0..(n_words - 1)
    |> Enum.map(fn i -> Bitwise.bor(elem(a, i), elem(b, i)) end)
    |> List.to_tuple()
  end
end
