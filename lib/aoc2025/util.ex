defmodule Aoc2025.Util do
  @type bfs_node :: {non_neg_integer(), non_neg_integer()}

  @type grid :: [[String.t()]]

  @type grid_obj :: %{grid: grid(), rows: non_neg_integer(), cols: non_neg_integer()}

  @spec parse_grid(String.t()) :: grid_obj()
  def parse_grid(input) do
    grid =
      input
      |> String.split("\n", trim: true)
      |> Enum.map(&String.graphemes/1)

    %{grid: grid, rows: length(grid), cols: length(hd(grid))}
  end

  @spec get_cell(grid_obj(), non_neg_integer(), non_neg_integer()) :: String.t()
  def get_cell(grid, r, c) do
    grid.grid |> Enum.at(r) |> Enum.at(c)
  end
end
