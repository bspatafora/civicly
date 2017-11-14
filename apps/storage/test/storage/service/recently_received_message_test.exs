defmodule Storage.Service.RecentlyReceivedMessageTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox

  alias Storage.{Helpers, RecentlyReceivedMessage}
  alias Storage.Service.RecentlyReceivedMessage, as: RecentlyReceivedMessageService

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  test "duplicate?/1 returns false if a message with the same sender and text was received outside the last 5 minutes" do
    sender = "5555555555"
    text = "Test message"
    unix_now = DateTime.to_unix(DateTime.utc_now())
    over_five_minutes_ago = DateTime.from_unix!(unix_now - 301)
    params =
      %{sender: sender,
        text: text,
        timestamp: over_five_minutes_ago}
    Helpers.insert_recently_received_message(params)
    message = Helpers.build_message(params)

    assert RecentlyReceivedMessageService.duplicate?(message) == false
  end

  test "duplicate?/1 returns false if no message with the same sender and text was received in the last 5 minutes" do
    sender = "5555555555"
    text = "Test message"
    same_sender_different_text =
      %{sender: sender,
        text: "Different message",
        timestamp: DateTime.utc_now()}
    same_text_different_sender =
      %{sender: "5555555556",
        text: text,
        timestamp: DateTime.utc_now()}
    Helpers.insert_recently_received_message(same_sender_different_text)
    Helpers.insert_recently_received_message(same_text_different_sender)
    message = Helpers.build_message(%{sender: sender, text: text})

    assert RecentlyReceivedMessageService.duplicate?(message) == false
  end

  test "duplicate?/1 returns true if a message with the same sender and text was received in the last 5 minutes" do
    sender = "5555555555"
    text = "Test message"
    unix_now = DateTime.to_unix(DateTime.utc_now())
    almost_five_minutes_ago = DateTime.from_unix!(unix_now - 299)
    params =
      %{sender: sender,
        text: text,
        timestamp: almost_five_minutes_ago}
    Helpers.insert_recently_received_message(params)
    message = Helpers.build_message(%{sender: sender, text: text})

    assert RecentlyReceivedMessageService.duplicate?(message) == true
  end

  test "insert_recently_received_message/1 inserts a recently received message" do
    message = Helpers.build_message()

    RecentlyReceivedMessageService.insert(message)

    recently_received_message = List.first(Storage.all(RecentlyReceivedMessage))
    assert recently_received_message.sender == message.sender
    assert recently_received_message.text == message.text
    assert recently_received_message.timestamp == message.timestamp
  end
end
