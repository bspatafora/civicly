defmodule Storage.Console do
  @moduledoc false

  import Ecto.Query, only: [from: 2]

  alias Storage.Conversation

  @name_pad 14
  @number_pad 4
  @timestamp_pad 15

  def conversations(iteration) do
    query = from Conversation, where: [iteration: ^iteration]
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
    IO.write display_phone(user.phone)
  end

  defp display_phone(phone) do
    area = String.slice(phone, 0..2)
    exchange = String.slice(phone, 3..5)
    line = String.slice(phone, 6..9)
    "(#{area}) #{exchange}-#{line}"
  end

  def messages(conversation_id) do
    conversation = Storage.get!(Conversation, conversation_id)
    conversation = conversation
      |> Storage.preload(:users)
      |> Storage.preload(:messages)

    display_messages_header()

    messages = Enum.sort(conversation.messages, &(&1.timestamp < &2.timestamp))
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
    hour = String.pad_leading(Integer.to_string(dt.hour), 2, "0")
    minute = String.pad_leading(Integer.to_string(dt.minute), 2, "0")
    second = String.pad_leading(Integer.to_string(dt.second), 2, "0")

    "#{dt.month}/#{dt.day} #{hour}:#{minute}:#{second}"
  end
end
