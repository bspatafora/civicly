defmodule Core.CommandParser do
  @moduledoc false

  def parse(text) do
    try do
      [command | rest] = String.split(text, " ", parts: 2)
      data = List.first(rest)

      cond do
        command == ":add" ->
          parse_add(data)
      end
    rescue
      _ -> {:invalid}
    end
  end

  defp parse_add(data) do
    {name, phone} = String.split_at(data, -10)
    name = String.trim_trailing(name)

    {:add, name, phone}
  end
end
