defmodule Storage.Console do
  @moduledoc false

  import Ecto.Query, only: [from: 2]

  alias Storage.Conversation

  @name_pad 14
  @number_pad 4
  @timestamp_pad 15

  def conversations(iteration) do
    query = from Conversation,
              where: [iteration: ^iteration],
              order_by: [asc: :id]
    conversations = Storage.all(query)
    conversations = conversations
      |> Storage.preload(:users)
      |> Storage.preload(:messages)

    display_conversations_header()

    conversations
      |> Enum.each(&(display_conversation(&1)))
  end

  defp display_conversations_header do
    IO.puts "  id  | msgs |  users"
    IO.puts "------+------+--------------------------------------------------------------------"
  end

  defp display_conversation(conversation) do
    id = Integer.to_string(conversation.id)
    message_count = Integer.to_string(length(conversation.messages))

    IO.write String.pad_leading(id, @number_pad)
    IO.write "  |"
    IO.write String.pad_leading(message_count, @number_pad)
    conversation.users |> Enum.each(&(display_user(&1)))
    IO.write "\n"
  end

  defp display_user(user) do
    IO.write "  |  "
    IO.write String.pad_trailing(user.name, @name_pad)
    IO.write user.phone
  end

  def messages(conversation_id) do
    conversation = Storage.get!(Conversation, conversation_id)
    conversation = conversation
      |> Storage.preload(:users)
      |> Storage.preload(:messages)

    display_messages_header()

    datetime_comparison = fn (a, b) -> DateTime.compare(a.timestamp, b.timestamp) == :lt end
    messages = Enum.sort(conversation.messages, &(datetime_comparison.(&1, &2)))
    messages |> Enum.each(&(display_message(&1)))
  end

  defp display_messages_header do
    IO.puts "  timestamp      |  user          |  message"
    IO.puts "-----------------+----------------+-----------------------------------------------"
  end

  defp display_message(message) do
    message = Storage.preload(message, :user)
    timestamp = format_datetime(message.timestamp)

    IO.write "  "
    IO.write String.pad_trailing(timestamp, @timestamp_pad)
    IO.write "|  "
    IO.write String.pad_trailing(message.user.name, @name_pad)
    IO.write "|  "
    IO.puts String.replace(message.text, "\n", "")
  end

  defp format_datetime(dt) do
    month = pad_leading_zero(dt.month)
    day = pad_leading_zero(dt.day)
    hour = pad_leading_zero(dt.hour)
    minute = pad_leading_zero(dt.minute)
    second = pad_leading_zero(dt.second)

    "#{month}/#{day} #{hour}:#{minute}:#{second}"
  end

  defp pad_leading_zero(integer) do
    String.pad_leading(Integer.to_string(integer), 2, "0")
  end
end
