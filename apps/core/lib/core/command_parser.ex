defmodule Core.CommandParser do
  @moduledoc false

  alias Strings, as: S

  def parse(text) do
    add_command = S.add_command()
    msg_command = S.msg_command()
    all_command = S.all_command()
    new_command = S.new_command()
    end_command = S.end_command()

    command_space_data = ~r/^:\b(add|msg|all|new)\b .+$/
    add_msg_all_or_new = String.match?(text, command_space_data)

    if add_msg_all_or_new or text == end_command do
      case split_on_first_space(text) do
        {^add_command, data} -> parse_add(data)
        {^msg_command, data} -> parse_msg(data)
        {^all_command, data} -> parse_all(data)
        {^new_command, data} -> parse_new(data)
        {^end_command, _} -> :end
      end
    else
      {:invalid}
    end
  end

  defp parse_add(data) do
    name_space_phone = ~r/^.+ \d{10}$/
    valid_data = String.match?(data, name_space_phone)

    if valid_data do
      {name, phone} = String.split_at(data, -10)
      name = String.trim_trailing(name)

      {:add, name, phone}
    else
      {:invalid}
    end
  end

  defp parse_msg(data) do
    phone_space_text = ~r/^\d{10} .+$/
    valid_data = String.match?(data, phone_space_text)

    if valid_data do
      {phone, text} = String.split_at(data, 10)
      text = String.trim_leading(text)

      {:msg, phone, text}
    else
      {:invalid}
    end
  end

  defp parse_all(data) do
    {:all, data}
  end

  defp parse_new(data) do
    question = ~r/^.+\?$/
    valid_data = String.match?(data, question)

    if valid_data do
      {:new, data}
    else
      {:invalid}
    end
  end

  defp split_on_first_space(string) do
    [first | rest] = String.split(string, " ", parts: 2)
    rest = List.first(rest)

    {first, rest}
  end
end
