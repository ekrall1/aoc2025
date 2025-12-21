defmodule Aoc2025.Days.Day10 do
  @moduledoc """
  Advent of Code 2025 - Day 10
  """

  @behaviour Aoc2025.Day

  @type goal :: [non_neg_integer()]

  @type button :: [non_neg_integer()]

  @type wiring :: [button()]

  @type joltage :: MapSet.t(non_neg_integer())

  @type problem_input :: %{goal: goal(), wiring: wiring(), joltage: joltage()}

  @line_re ~r/^\[([.#]+)\]\s*((?:\([0-9,\s]*\)\s*)*)\{([0-9,\s]+)\}\s*$/

  @spec part1(String.t()) :: String.t()
  @doc """
  Solves part 1 of day 10.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day10.txt")
      iex> Aoc2025.Days.Day10.part1(test_input)
      "Day 10 Part 1 not implemented yet"

  """
  @impl Aoc2025.Day
  def part1(input) do
    _ = parse_input(input)
    "part 1 not implemented yet"
  end

  @spec parse_input(String.t()) :: [problem_input()]
  defp parse_input(input) do
    lines = input |> String.split("\n")

    Enum.reduce(lines, [], fn line, acc ->
      parts = Regex.run(@line_re, line)

      [%{
        goal: parse_goal(Enum.at(parts, 1)),
        wiring: parse_wiring(Enum.at(parts, 2)),
        joltage: parse_joltage(Enum.at(parts, 3))
      } | acc]
    end)
  end

  @spec parse_goal(String.t()) :: goal()
  defp parse_goal(goal_s) do
    goal_s
    |> String.replace(".", "0")
    |> String.replace("#", "1")
    |> String.graphemes()
    |> Enum.map(&String.to_integer/1)
  end

  @spec parse_wiring(String.t()) :: wiring()
  defp parse_wiring(wiring_s) do
    Regex.scan(~r/\((?<inner>[0-9,\s]*)\)/, wiring_s, capture: ["inner"])
    |> Enum.map(fn [inner] ->
      inner
      |> String.trim()
      |> case do
        "" ->
          []
        s ->
          s
          |> String.split(",", trim: true)
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.to_integer/1)
      end
    end)
  end

  @spec parse_joltage(String.t()) :: joltage()
  defp parse_joltage(joltage_s) do
    joltage_s
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_integer/1)
    |> MapSet.new()
  end

  @spec formulate_machine_problem(problem_input()) :: String.t()
  defp formulate_machine_problem(%{goal: goal, wiring: wiring}) do
    n_lights = length(goal)
    m_buttons = length(wiring)

    decls = get_decls(m_buttons, n_lights)
    binaries = get_binaries(n_lights)
    int_vars = get_intvars(m_buttons)
    constraints = get_parity_constraints(goal, wiring)
    objective = get_objective(n_lights)

    Enum.join(decls ++ binaries ++ int_vars ++ constraints ++ [objective, "(check-sat)", "(get-objectives)"], "\n") <> "\n"
  end

  defp get_decls(m, n) do
    [
      "(set-option :model true)",
      "(set-option :pp.decimal true)"
    ] ++
      (for i <- 0..(n - 1), do: "(declare-const b#{i} Int)") ++
      (for j <- 0..(m - 1), do: "(declare-const k#{j} Int)")
  end

  defp get_binaries(n) do
    for i <- 0..(n - 1) do
      "(assert (or (= b#{i} 0) (= b#{i} 1)))"
    end
  end

  defp get_intvars(m) do
    for j <- 0..(m - 1) do
      "(assert (>= k#{j} 0))"
    end
  end

  defp get_parity_constraints(goal, wiring) do
    for {g_j, j} <- Enum.with_index(goal) do
      terms =
        wiring
        |> Enum.with_index()
        |> Enum.reduce([], fn {btn, i}, acc ->
          if j in btn, do: ["b#{i}" | acc], else: acc
        end)
        |> Enum.reverse()

      lhs =
        case terms do
          [] -> "0"
          [t] -> t
          ts -> "(+ " <> Enum.join(ts, " ") <> ")"
        end

      "(assert (= #{lhs} (+ #{g_j} (* 2 k#{j}))))"
    end
  end

  defp get_objective(n) do
      case n do
      0 -> "(minimize 0)"
      1 -> "(minimize b0)"
      _ -> "(minimize (+ " <> Enum.join((for i <- 0..(n - 1), do: "b#{i}"), " ") <> "))"
    end
  end

  @doc """
  Solves part 2 of day 10.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day10.txt")
      iex> Aoc2025.Days.Day10.part2(test_input)
      "Day 10 Part 2 not implemented yet"

  """
  @impl Aoc2025.Day
  def part2(_input) do
    # TODO: Implement Day 10 Part 2
    # input is the raw file content as a string
    "Day 10 Part 2 not implemented yet"
  end

  # Helper functions can go here
  # defp parse_input(input) do
  #   input
  #   |> String.trim()
  #   |> String.split("\n")
  # end
end
