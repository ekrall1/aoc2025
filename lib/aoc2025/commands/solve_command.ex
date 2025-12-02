defmodule Aoc2025.Commands.SolveCommand do
  @moduledoc """
  Command to solve an Advent of Code problem for a specific day and part.
  """

  @behaviour Aoc2025.Commands.Command

  defstruct [:day, :part, :inputfile]

  @type t :: %__MODULE__{
          day: integer(),
          part: integer(),
          inputfile: String.t()
        }

  @doc """
  Execute the solve command.
  """
  @impl Aoc2025.Commands.Command
  def execute(%__MODULE__{day: day, part: part, inputfile: inputfile} = _command) do
    IO.puts("Running Day #{day}, Part #{part} with input file: #{inputfile}")

    with {:ok, input_data} <- load_input(inputfile),
         {:ok, result} <- solve(day, part, input_data) do
      display_result(result)
      :ok
    else
      {:error, reason} ->
        IO.puts("Error: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Load and parse the input file.
  """
  def load_input(filepath) do
    case File.read(filepath) do
      {:ok, content} ->
        # Only remove trailing whitespace at the very end
        cleaned_content = String.trim_trailing(content)
        {:ok, cleaned_content}

      {:error, :enoent} ->
        {:error, "File not found: #{filepath}"}

      {:error, :eacces} ->
        {:error, "Permission denied: #{filepath}"}

      {:error, reason} ->
        {:error, "Failed to read file #{filepath}: #{reason}"}
    end
  end

  @doc """
  Route to the appropriate solution based on day and part.
  """
  def solve(day, part, input_data) do
    # Build module name dynamically: Aoc2025.Days.Day01, Day02, etc.
    day_string = String.pad_leading(Integer.to_string(day), 2, "0")
    module_name = Module.concat([Aoc2025.Days, "Day#{day_string}"])

    try do
      # Check if module exists and has the function
      if Code.ensure_loaded?(module_name) do
        case part do
          1 -> {:ok, module_name.part1(input_data)}
          2 -> {:ok, module_name.part2(input_data)}
          _ -> {:error, "Invalid part: #{part}"}
        end
      else
        {:error, "Day #{day} not implemented yet"}
      end
    rescue
      UndefinedFunctionError ->
        {:error, "Day #{day} exists but part #{part} not implemented"}

      error ->
        {:error, "Error running Day #{day} Part #{part}: #{inspect(error)}"}
    end
  end

  @doc """
  Display the solution result.
  """
  def display_result(result) do
    # TODO: Implement result display
    # - Format the result nicely
    # - Maybe include timing information using :timer.tc/1
    # - Handle different result types (integer, string, etc.)
    # - Consider adding color output for better UX

    IO.puts("Result: #{result}")
  end
end
