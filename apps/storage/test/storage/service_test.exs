defmodule Storage.ServiceTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Storage.{Conversation, Service, User}

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  def insert_user do
    params = %{name: "Test User", phone: Helpers.random_phone}

    changeset = User.changeset(%User{}, params)
    {:ok, user} = Storage.insert(changeset)
    user
  end

  def insert_conversation(user1, user2, start) do
    params =
      %{left_user_id: user1.id,
        right_user_id: user2.id,
        proxy_phone: Helpers.random_phone,
        start: start}

    changeset = Conversation.changeset(%Conversation{}, params)
    {:ok, conversation} = Storage.insert(changeset)
    conversation
  end

  test "current_partner_and_proxy_phones/1 provides the partner and proxy phone numbers of the user's current conversation" do
    user1 = insert_user()
    user2 = insert_user()
    old_start = "2017-03-23 00:00:00"
    current_start = "2017-03-27 00:00:00"

    insert_conversation(user1, user2, old_start)
    current_conversation = insert_conversation(user1, user2, current_start)

    {partner_phone, proxy_phone} =
      Service.current_partner_and_proxy_phones(user1.phone)

    assert partner_phone == user2.phone
    assert proxy_phone == current_conversation.proxy_phone

    {partner_phone, proxy_phone} =
      Service.current_partner_and_proxy_phones(user2.phone)

    assert partner_phone == user1.phone
    assert proxy_phone == current_conversation.proxy_phone
  end
end
