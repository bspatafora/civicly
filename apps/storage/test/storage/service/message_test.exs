defmodule Storage.Service.MessageTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox

  alias Storage.{Helpers, Message}
  alias Storage.Service.Message, as: MessageService

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  test "insert/3 inserts a message" do
    user = Helpers.insert_user()
    conversation = Helpers.insert_conversation(
      %{users: [user.id, Helpers.insert_user().id]})
    message = Helpers.build_message()

    MessageService.insert(message, user.id, conversation.id)

    retrieved_message = List.first(Storage.all(Message))
    assert retrieved_message.conversation_id == conversation.id
    assert retrieved_message.user_id == user.id
    assert retrieved_message.text == message.text
    assert retrieved_message.timestamp == message.timestamp
    assert retrieved_message.uuid == message.uuid
  end
end
