defmodule Core.CommandParser do
  @moduledoc false

  def parse(text) do
    [command | rest] = String.split(text, " ", parts: 2)
    data = List.first(rest)

    if command == ":add" do
      parse_add(data)
    else
      {:invalid}
    end
  rescue
    _ -> {:invalid}
  end

  defp parse_add(data) do
    {name, phone} = String.split_at(data, -10)
    name = String.trim_trailing(name)

    {:add, name, phone}
  end
end
