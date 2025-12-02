defmodule Aoc2025.CLI do
  @moduledoc """
  Command line interface for Advent of Code 2025 solutions.

  Usage:
    ./aoc2025 --day 1 --part 1 --inputfile input.txt
  """

  alias Aoc2025.Commands.SolveCommand

  def main(args) do
    args
    |> parse_args()
    |> execute_command()
  end

  @doc """
  Parse command line arguments and return a command struct.
  """
  def parse_args(args) do
    {options, _, _} =
      OptionParser.parse(args,
        strict: [
          day: :integer,
          part: :integer,
          inputfile: :string,
          help: :boolean
        ],
        aliases: [h: :help]
      )

    case options do
      [help: true] -> {:help}
      _ -> build_solve_command(options)
    end
  end

  defp build_solve_command(options) do
    case validate_args(options) do
      {:ok, validated_args} ->
        {:solve,
         %SolveCommand{
           day: Keyword.get(validated_args, :day),
           part: Keyword.get(validated_args, :part),
           inputfile: Keyword.get(validated_args, :inputfile)
         }}

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Validate that all required arguments are present and valid.
  """
  def validate_args(options) do
    with {:ok, day} <- validate_day(Keyword.get(options, :day)),
         {:ok, part} <- validate_part(Keyword.get(options, :part)),
         {:ok, inputfile} <- validate_inputfile(Keyword.get(options, :inputfile)) do
      {:ok, [day: day, part: part, inputfile: inputfile]}
    else
      {:error, message} -> {:error, message}
    end
  end

  defp validate_day(nil), do: {:error, "Day is required"}

  defp validate_day(day) when day < 1 or day > 25 do
    {:error, "Day must be between 1 and 25, got: #{day}"}
  end

  defp validate_day(day), do: {:ok, day}

  defp validate_part(nil), do: {:error, "Part is required"}

  defp validate_part(part) when part not in [1, 2] do
    {:error, "Part must be 1 or 2, got: #{part}"}
  end

  defp validate_part(part), do: {:ok, part}

  defp validate_inputfile(nil), do: {:error, "Input file is required"}

  defp validate_inputfile(filepath) do
    case File.exists?(filepath) do
      true -> {:ok, filepath}
      false -> {:error, "Input file does not exist: #{filepath}"}
    end
  end

  @doc """
  Execute the parsed command.
  """
  def execute_command({:help}) do
    print_usage()
  end

  def execute_command({:solve, command}) do
    SolveCommand.execute(command)
  end

  def execute_command({:error, message}) do
    IO.puts("Error: #{message}")
    print_usage()
    System.halt(1)
  end

  @doc """
  Print usage information.
  """
  def print_usage do
    IO.puts("""
    Usage: ./aoc2025 --day <day> --part <part> --inputfile <file>

    Arguments:
      --day       Day number (1-25)
      --part      Part number (1 or 2)
      --inputfile Path to input file
      -h, --help  Show this help message

    Example:
      ./aoc2025 --day 1 --part 1 --inputfile inputs/day01.txt
    """)
  end
end
