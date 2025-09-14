ExUnit.start()

for path <- Path.wildcard(Path.expand("../lib/aoc2025/days/day*.ex", __DIR__)) do
  Code.compile_file(path)
end