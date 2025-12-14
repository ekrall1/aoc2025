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
      # if we are on the last row, no moves
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
          # count this caret as a split trigger
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

  @doc """
  Solves part 2 of day 07.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day07.txt")
      iex> Aoc2025.Days.Day07.part2(test_input)
      "Day 07 Part 2 not implemented yet"

  """
  @impl Aoc2025.Day
  def part2(_input) do
    "Day 07 Part 2 not implemented yet"
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
end
