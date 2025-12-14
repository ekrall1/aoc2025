defmodule Aoc2025.Days.Day07 do
  @moduledoc """
  Advent of Code 2025 - Day 07
  """

  @behaviour Aoc2025.Day

  @typedoc "node type"
  @type bfs_node :: {non_neg_integer(), non_neg_integer()}

  @typedoc "grid"
  @type grid :: [[String.t()]]

  @typedoc "grid object"
  @type grid_obj :: %{grid: grid(), rows: non_neg_integer(), cols: non_neg_integer()}

  @type visit_fn ::
          (bfs_node(), [bfs_node()], [bfs_node()] -> {[bfs_node()], [bfs_node()]})

  @type path_count :: non_neg_integer()

  @type ways_map :: %{optional(bfs_node()) => path_count()}

  @spec part1(String.t()) :: String.t()
  @doc """
  Solves part 1 of day 07.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day07.txt")
      iex> Aoc2025.Days.Day07.part1(test_input)
      "21"

  """
  @impl Aoc2025.Day
  def part1(input) do
    grid = Aoc2025.Util.parse_grid(input)

    goal = fn {r, _c} -> r == -1 end

    neighbors = fn {r, c} ->
      if r + 1 >= grid.rows do
        []
      else
        if Aoc2025.Util.get_cell(grid, r + 1, c) == "^" do
          for dc <- [-1, 1],
              nc = c + dc,
              nc >= 0 and nc < grid.cols,
              do: {r + 1, nc}
        else
          [{r + 1, c}]
        end
      end
    end

    visit_fn = fn {r, c}, acc, splits ->
      splits2 =
        if r + 1 < grid.rows and Aoc2025.Util.get_cell(grid, r + 1, c) == "^" do
          [{r + 1, c} | splits]
        else
          splits
        end

      {[{r, c} | acc], splits2}
    end

    start = get_start(grid)

    {_, _, splits} = bfs(start, goal, neighbors, visit_fn)
    set = MapSet.new(splits)
    Integer.to_string(MapSet.size(set))
  end

  @spec part2(String.t()) :: String.t()
  @doc """
  Solves part 2 of day 07.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day07.txt")
      iex> Aoc2025.Days.Day07.part2(test_input)
      "40"

  """
  @impl Aoc2025.Day
  def part2(input) do
    grid = Aoc2025.Util.parse_grid(input)
    start = get_start(grid)
    Integer.to_string(count_paths(grid, start))
  end

  @spec bfs(
          bfs_node(),
          (bfs_node() -> boolean()),
          (bfs_node() -> [bfs_node()]),
          visit_fn()
        ) ::
          {:no_path, [bfs_node()], [bfs_node()]}
          | {:found, bfs_node(), [bfs_node()], [bfs_node()]}
  defp bfs(start, goal?, neighbors, visit_fn) do
    queue = :queue.from_list([start])
    visited = MapSet.new([start])
    splits = []
    do_bfs(queue, visited, splits, goal?, neighbors, visit_fn, [])
  end

  @spec do_bfs(
          :queue.queue(bfs_node()),
          MapSet.t(bfs_node()),
          [bfs_node()],
          (bfs_node() -> boolean()),
          (bfs_node() -> [bfs_node()]),
          visit_fn(),
          list(bfs_node())
        ) ::
          {:no_path, list(bfs_node()), list(bfs_node())}
          | {:found, bfs_node(), list(bfs_node()), list(bfs_node())}

  defp do_bfs(queue, visited, splits, goal?, neighbors, visit_fn, acc) do
    case :queue.out(queue) do
      {:empty, _} ->
        {:no_path, acc, splits}

      {{:value, node}, queue_rest} ->
        {acc2, splits2} = visit_fn.(node, acc, splits)

        cond do
          goal?.(node) ->
            {:found, node, acc2, splits2}

          true ->
            {queue2, visited2} = enqueue_neighbors(node, queue_rest, visited, neighbors)
            do_bfs(queue2, visited2, splits2, goal?, neighbors, visit_fn, acc2)
        end
    end
  end

  @spec enqueue_neighbors(
          bfs_node(),
          :queue.queue(bfs_node()),
          MapSet.t(bfs_node()),
          (bfs_node() -> [bfs_node()])
        ) ::
          {:queue.queue(bfs_node()), MapSet.t(bfs_node())}
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

  @spec get_start(grid_obj()) :: bfs_node()
  def get_start(%{grid: rows}) do
    rows
    |> Enum.with_index()
    |> Enum.find_value(fn {row, r} ->
      row
      |> Enum.with_index()
      |> Enum.find_value(fn {cell, c} ->
        if cell == "S", do: {r, c}, else: nil
      end)
    end)
  end

  @spec count_paths(grid_obj(), bfs_node()) :: path_count()
  defp count_paths(grid, {sr, sc}) do
    rows = grid.rows
    cols = grid.cols

    ways0 = %{{sr, sc} => 1}

    ways_final =
      Enum.reduce(0..(rows - 2), ways0, fn r, ways ->
        Enum.reduce(0..(cols - 1), ways, fn c, ways2 ->
          count = Map.get(ways2, {r, c}, 0)

          if count == 0 do
            ways2
          else
            if Aoc2025.Util.get_cell(grid, r + 1, c) == "^" do
              ways2
              |> maybe_add({r + 1, c - 1}, count, cols)
              |> maybe_add({r + 1, c + 1}, count, cols)
            else
              Map.update(ways2, {r + 1, c}, count, &(&1 + count))
            end
          end
        end)
      end)

    Enum.reduce(0..(cols - 1), 0, fn c, acc ->
      acc + Map.get(ways_final, {rows - 1, c}, 0)
    end)
  end

  @spec maybe_add(ways_map(), bfs_node(), path_count(), non_neg_integer()) :: ways_map()
  defp maybe_add(ways, {r, c}, count, cols) do
    if c >= 0 and c < cols do
      Map.update(ways, {r, c}, count, &(&1 + count))
    else
      ways
    end
  end
end
