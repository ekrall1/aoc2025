defmodule Aoc2025.Days.Day11 do
  @moduledoc """
  Advent of Code 2025 - Day 11
  """

  @behaviour Aoc2025.Day

  @type graph_node :: String.t()
  @type graph :: %{graph_node() => MapSet.t(graph_node())}
  @type memo :: %{graph_node() => non_neg_integer()}
  @type visiting :: MapSet.t(graph_node())

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

      iex> test_input = File.read!("tests/test_input/day11.txt")
      iex> Aoc2025.Days.Day11.part2(test_input)
      "Day 11 Part 2 not implemented yet"

  """
  @impl Aoc2025.Day
  def part2(_input) do
    # TODO: Implement Day 11 Part 2
    # input is the raw file content as a string
    "Day 11 Part 2 not implemented yet"
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
end
