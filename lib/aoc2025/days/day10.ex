defmodule Aoc2025.Days.Day10 do
  @moduledoc """
  Advent of Code 2025 - Day 10
  """

  @behaviour Aoc2025.Day

  @type goal :: [non_neg_integer()]

  @type button :: [non_neg_integer()]

  @type wiring :: [button()]

  @type joltage :: [non_neg_integer()]

  @type problem_input :: %{goal: goal(), wiring: wiring(), joltage: joltage()}

  @line_re ~r/^\[([.#]+)\]\s*((?:\([0-9,\s]*\)\s*)*)\{([0-9,\s]+)\}\s*$/

  @spec part1(String.t()) :: String.t()
  @doc """
  Solves part 1 of day 10.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day10.txt")
      iex> Aoc2025.Days.Day10.part1(test_input)
      "7"

  """
  @impl Aoc2025.Day
  def part1(input) do
    problems = parse_input(input)

    total =
      problems
      |> Enum.map(fn p ->
        base = formulate_machine_problem(p)
        n = length(p.wiring)
        model = get_model(n, base)
        out = run_model!(model)
        sum_soln_vars(out)
      end)

    Enum.reduce(total, 0, fn ans, acc ->
      acc + ans
    end)
    |> Integer.to_string()
  end

  @spec part2(String.t()) :: String.t()
  @doc """
  Solves part 2 of day 10.

  ## Examples

      iex> test_input = File.read!("tests/test_input/day10.txt")
      iex> Aoc2025.Days.Day10.part1(test_input)
      "33"

  """
  @impl Aoc2025.Day
  def part2(input) do
    problems = parse_input(input)

    total =
      problems
      |> Enum.map(fn p ->
        base = formulate_joltage_problem(p)
        n = length(p.wiring)
        model = get_model(n, base)
        out = run_model!(model)
        sum_soln_vars(out)
      end)

    Enum.reduce(total, 0, fn ans, acc ->
      acc + ans
    end)
    |> Integer.to_string()
  end

  @spec parse_input(String.t()) :: [problem_input()]
  defp parse_input(input) do
    lines = input |> String.split("\n")

    Enum.reduce(lines, [], fn line, acc ->
      parts = Regex.run(@line_re, line)

      [
        %{
          goal: parse_goal(Enum.at(parts, 1)),
          wiring: parse_wiring(Enum.at(parts, 2)),
          joltage: parse_joltage(Enum.at(parts, 3))
        }
        | acc
      ]
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
  end

  @spec formulate_machine_problem(problem_input()) :: String.t()
  defp formulate_machine_problem(%{goal: goal, wiring: wiring}) do
    n_lights = length(goal)
    m_buttons = length(wiring)

    decls = get_decls(m_buttons, n_lights)
    binaries = get_binaries(m_buttons)
    int_vars = get_intvars(n_lights)
    constraints = get_parity_constraints(goal, wiring)
    objective = get_objective(m_buttons)

    Enum.join(
      decls ++
        binaries ++ int_vars ++ constraints ++ [objective, "(check-sat)", "(get-objectives)"],
      "\n"
    ) <> "\n"
  end

  @spec formulate_joltage_problem(problem_input()) :: String.t()
  defp formulate_joltage_problem(%{joltage: joltage, wiring: wiring}) do
    m_buttons = length(wiring)

    decls = get_decls_p2(m_buttons)
    presses = get_press_nonneg(m_buttons)
    constraints = get_joltage_constraints(joltage, wiring)
    objective = get_objective(m_buttons)

    Enum.join(
      decls ++
        presses ++ constraints ++ [objective, "(check-sat)", "(get-objectives)"],
      "\n"
    ) <> "\n"
  end

  @spec get_decls(non_neg_integer(), non_neg_integer()) :: [String.t()]
  defp get_decls(m, n) do
    [
      "(set-option :model true)",
      "(set-option :pp.decimal true)"
    ] ++
      for(i <- 0..(m - 1), do: "(declare-const b#{i} Int)") ++
      for j <- 0..(n - 1), do: "(declare-const k#{j} Int)"
  end

  @spec get_decls_p2(non_neg_integer()) :: [String.t()]
  defp get_decls_p2(m) do
    [
      "(set-option :model true)",
      "(set-option :pp.decimal true)"
    ] ++
      for(i <- 0..(m - 1), do: "(declare-const b#{i} Int)")
  end

  @spec get_binaries(non_neg_integer()) :: [String.t()]
  defp get_binaries(n) do
    for i <- 0..(n - 1) do
      "(assert (or (= b#{i} 0) (= b#{i} 1)))"
    end
  end

  @spec get_intvars(non_neg_integer()) :: [String.t()]
  defp get_intvars(m) do
    for j <- 0..(m - 1) do
      "(assert (>= k#{j} 0))"
    end
  end

  @spec get_press_nonneg(non_neg_integer()) :: [String.t()]
  defp get_press_nonneg(m_buttons) do
    for i <- 0..(m_buttons - 1) do
      "(assert (>= b#{i} 0))"
    end
  end

  @spec get_parity_constraints(goal(), wiring()) :: [String.t()]
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

  @spec get_joltage_constraints(joltage(), wiring()) :: [String.t()]
  defp get_joltage_constraints(joltage, wiring) do
    for {g_j, j} <- Enum.with_index(joltage) do
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

      "(assert (= #{lhs} #{g_j}))"
    end
  end

  @spec get_objective(non_neg_integer()) :: String.t()
  defp get_objective(n) do
    case n do
      0 -> "(minimize 0)"
      1 -> "(minimize b0)"
      _ -> "(minimize (+ " <> Enum.join(for(i <- 0..(n - 1), do: "b#{i}"), " ") <> "))"
    end
  end

  @spec get_model(non_neg_integer(), String.t()) :: String.t()
  defp get_model(n, base) do
    model =
      if n == 0 do
        base
      else
        vars = Enum.join(for(i <- 0..(n - 1), do: "b#{i}"), " ")
        base <> "(get-value (#{vars}))\n"
      end

    model <> "(exit)\n"
  end

  @spec run_model!(String.t()) :: String.t()
  defp run_model!(model) do
    try do
      run!(model)
    rescue
      e ->
        IO.puts("=== Z3 MODEL BEGIN ===")
        IO.puts(model)
        IO.puts("=== Z3 MODEL END ===")
        reraise(e, __STACKTRACE__)
    end
  end

  @spec run!(String.t()) :: String.t()
  def run!(smt2) do
    z3 = System.find_executable("z3") || raise "z3 not found in PATH"

    port =
      Port.open({:spawn_executable, z3}, [
        :binary,
        :exit_status,
        :stderr_to_stdout,
        args: ["-in", "-smt2"]
      ])

    Port.command(port, smt2)
    Port.command(port, "\n")

    collect(port, "")
  end

  @spec collect(port(), String.t()) :: String.t()
  defp collect(port, acc) do
    receive do
      {^port, {:data, chunk}} ->
        collect(port, acc <> chunk)

      {^port, {:exit_status, 0}} ->
        acc

      {^port, {:exit_status, status}} ->
        raise "z3 failed (exit #{status}):\n#{acc}"
    after
      30_000 ->
        Port.close(port)
        raise "z3 timed out:\n#{acc}"
    end
  end

  @spec sum_soln_vars(String.t()) :: non_neg_integer()
  defp sum_soln_vars(out) when is_binary(out) do
    Regex.scan(~r/\(\s*b\d+\s+(\d+)\s*\)/, out)
    |> Enum.reduce(0, fn [_full, v], acc ->
      acc + String.to_integer(v)
    end)
  end
end
