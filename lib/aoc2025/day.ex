defmodule Aoc2025.Day do
  @moduledoc """
  Behaviour for Advent of Code day solutions.
  Each day must implement part1 and part2 functions.
  """

  @callback part1(input :: String.t()) :: String.t()
  @callback part2(input :: String.t()) :: String.t()
end
