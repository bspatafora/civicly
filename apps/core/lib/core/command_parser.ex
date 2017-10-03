defmodule Core.CommandParser do
  @moduledoc false

  alias Strings, as: S

  def parse(text) do
    add_command = S.add_command()
    msg_command = S.msg_command()
    all_command = S.all_command()
    new_command = S.new_command()
    notify_command = S.notify_command()
    end_command = S.end_command()
    news_command = S.news_command()

    command = ~r/(^:\b(add|msg|all|new|notify)\b .+$|^:(end|news)$)/
    if String.match?(text, command) do
      case split_on_first_space(text) do
        {^add_command, data} -> parse_add(data)
        {^msg_command, data} -> parse_msg(data)
        {^all_command, data} -> {:all, data}
        {^new_command, data} -> parse_new(data)
        {^notify_command, data} -> parse_notify(data)
        {^end_command, _} -> :end
        {^news_command, _} -> :news
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

  defp parse_new(data) do
    question = ~r/^.+\?$/
    valid_data = String.match?(data, question)

    if valid_data do
      {:new, data}
    else
      {:invalid}
    end
  end

  defp parse_notify(data) do
    question = ~r/^.+\?$/
    valid_data = String.match?(data, question)

    if valid_data do
      {:notify, data}
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
