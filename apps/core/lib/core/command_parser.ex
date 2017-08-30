defmodule Core.CommandParser do
  @moduledoc false

  alias Strings, as: S

  def parse(text) do
    [command | rest] = String.split(text, " ", parts: 2)
    data = List.first(rest)

    cond do
      command == S.add_command() ->
        parse_add(data)
      command == S.msg_command() ->
        parse_msg(data)
      command == S.new_command() ->
        parse_new(data)
      true ->
        {:invalid}
    end
  rescue
    _ -> {:invalid}
  end

  defp parse_add(data) do
    name_space_phone = ~r/^.+ \d{10}$/
    if String.match?(data, name_space_phone) do
      {name, phone} = String.split_at(data, -10)
      name = String.trim_trailing(name)

      {:add, name, phone}
    else
      {:invalid}
    end
  end

  defp parse_msg(data) do
    phone_space_text = ~r/^\d{10} .+$/
    if String.match?(data, phone_space_text) do
      {phone, text} = String.split_at(data, 10)
      text = String.trim_leading(text)

      {:msg, phone, text}
    else
      {:invalid}
    end
  end

  defp parse_new(data) do
    number_space_question = ~r/^\d+ .+\?$/
    if String.match?(data, number_space_question) do
      [number | rest] = String.split(data, " ", parts: 2)
      question = List.first(rest)

      {:new, number, question}
    else
      {:invalid}
    end
  end
end
