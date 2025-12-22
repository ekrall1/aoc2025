defmodule Aoc2025.Days.Day11 do
  @moduledoc """
  Advent of Code 2025 - Day 11
  """

  @behaviour Aoc2025.Day

  @type graph_node :: String.t()
  @type graph :: %{graph_node() => MapSet.t(graph_node())}
  @type memo :: %{graph_node() => non_neg_integer()}
  @type visiting :: MapSet.t(graph_node())
  @type idx_map :: %{graph_node() => non_neg_integer()}
  @type mask :: non_neg_integer()
  @type memo_req :: %{{graph_node(), mask()} => non_neg_integer()}
  @type visiting_req :: MapSet.t({graph_node(), mask()})

  @spec part1(String.t()) :: String.t()
  @doc """
  Solves part 1 of day 11.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day11.txt")
      iex> Aoc2025.Days.Day11.part1(test_input)
      "5"

  """
  @impl Aoc2025.Day
  def part1(input) do
    graph = parse_input(input)
    paths = count_paths(graph, "you")
    Integer.to_string(paths)
  end

  @spec part2(String.t()) :: String.t()
  @doc """
  Solves part 2 of day 11.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day11-2.txt")
      iex> Aoc2025.Days.Day11.part2(test_input)
      "2"

  """
  @impl Aoc2025.Day
  def part2(input) do
    graph = parse_input(input)

    required = ["dac", "fft"]
    req_idx = idx_map(required)
    all_mask = all_required_mask(req_idx)

    start = "svr"
    start_mask = maybe_mark(0, start, req_idx)

    {count, _memo} =
      count_required_dfs(graph, start, start_mask, req_idx, all_mask, %{}, MapSet.new())

    Integer.to_string(count)
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

  @spec parse_line(String.t()) :: {graph_node(), [graph_node()]}
  defp parse_line(line) do
    [lhs, rhs] = String.split(line, ~r/\s*:\s*/, parts: 2)

    neighbors =
      rhs
      |> String.split(~r/\s+/, trim: true)

    {lhs, neighbors}
  end

  @spec count_paths(graph(), graph_node()) :: non_neg_integer()
  defp count_paths(graph, start) do
    {count, _memo} = count_paths_dfs(graph, start, %{}, MapSet.new())
    count
  end

  @spec count_paths_dfs(graph(), graph_node(), memo(), visiting()) ::
          {non_neg_integer(), memo()}
  defp count_paths_dfs(graph, node, memo, visiting) do
    cond do
      node == "out" ->
        {1, memo}

      Map.has_key?(memo, node) ->
        {memo[node], memo}

      MapSet.member?(visiting, node) ->
        raise "cycle detected while counting paths at node=#{inspect(node)}"

      true ->
        nbrs =
          graph
          |> Map.get(node, MapSet.new())
          |> MapSet.to_list()

        visiting2 = MapSet.put(visiting, node)

        {sum, memo2} =
          Enum.reduce(nbrs, {0, memo}, fn nb, {acc, m} ->
            {cnt, m2} = count_paths_dfs(graph, nb, m, visiting2)
            {acc + cnt, m2}
          end)

        memo3 = Map.put(memo2, node, sum)
        {sum, memo3}
    end
  end

  @spec idx_map([graph_node()]) :: idx_map()
  defp idx_map(req_nodes) do
    req_nodes
    |> Enum.uniq()
    |> Enum.with_index()
    |> Map.new()
  end

  @spec all_required_mask(idx_map()) :: mask()
  defp all_required_mask(req_idx) do
    k = map_size(req_idx)
    Bitwise.<<<(1, k) - 1
  end

  defp maybe_mark(mask, node, idx_map) do
    case Map.fetch(idx_map, node) do
      {:ok, bit} -> Bitwise.bor(mask, Bitwise.<<<(1, bit))
      :error -> mask
    end
  end

  @spec count_required_dfs(
          graph(),
          graph_node(),
          mask(),
          idx_map(),
          mask(),
          memo_req(),
          visiting_req()
        ) :: {non_neg_integer(), memo_req()}
  defp count_required_dfs(graph, node, mask, req_idx, all_mask, memo, visiting) do
    state = {node, mask}

    cond do
      node == "out" ->
        if mask == all_mask, do: {1, memo}, else: {0, memo}

      Map.has_key?(memo, state) ->
        {memo[state], memo}

      MapSet.member?(visiting, state) ->
        raise "cycle detected in state graph at #{inspect(state)}"

      true ->
        nbrs =
          graph
          |> Map.get(node, MapSet.new())
          |> MapSet.to_list()

        visiting2 = MapSet.put(visiting, state)

        {sum, memo2} =
          Enum.reduce(nbrs, {0, memo}, fn nb, {acc, m} ->
            mask2 = maybe_mark(mask, nb, req_idx)
            {cnt, m2} = count_required_dfs(graph, nb, mask2, req_idx, all_mask, m, visiting2)
            {acc + cnt, m2}
          end)

        memo3 = Map.put(memo2, state, sum)
        {sum, memo3}
    end
  end
end
