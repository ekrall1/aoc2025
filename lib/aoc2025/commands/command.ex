defmodule Aoc2025.Commands.Command do
  @moduledoc """
  Behaviour for CLI commands.
  """

  @callback execute(command :: struct()) :: :ok | {:error, String.t()}
end
