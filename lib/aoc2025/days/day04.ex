defmodule Aoc2025.Days.Day04 do
  @moduledoc """
  Advent of Code 2025 - Day 04
  """

  @behaviour Aoc2025.Day

  @typedoc "node type"
  @type bfs_node :: {non_neg_integer(), non_neg_integer()}

  @doc """
  Solves part 1 of day 04.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day04.txt")
      iex> Aoc2025.Days.Day04.part1(test_input)
      "13"

  """
  @impl Aoc2025.Day
  def part1(input) do
    grid = parse_grid(input)
    goal = fn {r, c} -> r == grid.rows - 1 and c == grid.cols - 1 end

    neighbors = fn {r, c} ->
      for {dr, dc} <- [{1, 0}, {-1, 0}, {0, 1}, {0, -1}],
          nr = r + dr,
          nc = c + dc,
          nr >= 0 and nr < grid.rows and nc >= 0 and nc < grid.cols,
          do: {nr, nc}
    end

    visit_fn = fn {r, c}, acc ->
      if is_at(grid, r, c) and neighbor_at_count(grid, r, c) < 4 do
        [{r, c} | acc]
      else
        acc
      end
    end

    {_, _, ans} = bfs({0, 0}, goal, neighbors, visit_fn)
    Integer.to_string(length(ans))
  end

  defp parse_grid(input) do
    grid =
      input
      |> String.split("\n", trim: true)
      |> Enum.map(&String.graphemes/1)

    %{grid: grid, rows: length(grid), cols: length(hd(grid))}
  end

  defp update_grid(grid, removed) do
    new_grid =
      Enum.reduce(removed, grid.grid, fn {r, c}, g ->
        List.update_at(g, r, fn row ->
          List.update_at(row, c, fn _ -> "." end)
        end)
      end)

    %{grid | grid: new_grid}
  end

  defp get_cell(grid, r, c) do
    grid.grid |> Enum.at(r) |> Enum.at(c)
  end

  defp is_at(grid, r, c) do
    get_cell(grid, r, c) == "@"
  end

  defp neighbor_at_count(grid, r, c) do
    [{0, 1}, {1, 0}, {0, -1}, {-1, 0}, {1, 1}, {-1, 1}, {1, -1}, {-1, -1}]
    |> Enum.count(fn {dr, dc} ->
      nr = r + dr
      nc = c + dc
      nr >= 0 and nr < grid.rows and nc >= 0 and nc < grid.cols and get_cell(grid, nr, nc) == "@"
    end)
  end

  defp bfs(start, goal?, neighbors, visit_fn) do
    queue = :queue.from_list([start])
    visited = MapSet.new([start])
    do_bfs(queue, visited, goal?, neighbors, visit_fn, [])
  end

  defp do_bfs(queue, visited, goal?, neighbors, visit_fn, acc) do
    case :queue.out(queue) do
      {:empty, _} ->
        {:no_path, acc}

      {{:value, node}, queue_rest} ->
        acc2 = visit_fn.(node, acc)

        cond do
          goal?.(node) ->
            {:found, node, acc2}

          true ->
            {queue2, visited2} = enqueue_neighbors(node, queue_rest, visited, neighbors)
            do_bfs(queue2, visited2, goal?, neighbors, visit_fn, acc2)
        end
    end
  end

  defp enqueue_neighbors(node, queue, visited, neighbors) do
    Enum.reduce(neighbors.(node), {queue, visited}, fn nb, {q, vis} ->
      if nb in vis do
        {q, vis}
      else
        {
          :queue.in(nb, q),
          MapSet.put(vis, nb)
        }
      end
    end)
  end

  @doc """
  Solves part 2 of day 04.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day04.txt")
      iex> Aoc2025.Days.Day04.part2(test_input)
      "43"

  """
  @impl Aoc2025.Day
  def part2(input) do
    grid = parse_grid(input)

    {_, ans} = recurse(grid, [])

    Integer.to_string(length(ans))
  end

  defp recurse(grid, removed) do
    {grid2, new_removed} = part2_helper(grid, removed)

    case new_removed do
      [] ->
        {grid2, removed}

      _ ->
        recurse(grid2, removed ++ new_removed)
    end
  end

  defp part2_helper(grid, removed) do
    grid = update_grid(grid, removed)
    goal = fn {r, c} -> r == grid.rows - 1 and c == grid.cols - 1 end

    neighbors = fn {r, c} ->
      for {dr, dc} <- [{1, 0}, {-1, 0}, {0, 1}, {0, -1}],
          nr = r + dr,
          nc = c + dc,
          nr >= 0 and nr < grid.rows and nc >= 0 and nc < grid.cols,
          do: {nr, nc}
    end

    visit_fn = fn {r, c}, acc ->
      if is_at(grid, r, c) and neighbor_at_count(grid, r, c) < 4 do
        [{r, c} | acc]
      else
        acc
      end
    end

    {_, _, ans} = bfs({0, 0}, goal, neighbors, visit_fn)
    {grid, ans}
  end
end
