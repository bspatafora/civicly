defmodule Storage.Service do
  @moduledoc false

  import Ecto.Changeset
  import Ecto.Query

  alias Storage.{Conversation, Message, SMSRelay, User}

  def current_conversation_details(user_phone) do
    user_id = fetch_user_by_phone(user_phone).id
    conversation = fetch_current_conversation(user_id)
    conversation = Storage.preload(conversation, :sms_relay)

    partner_id = partner_id(conversation, user_id)
    partner = fetch_user(partner_id)

    {partner.phone, conversation.sms_relay.ip, conversation.sms_relay.phone}
  end

  def store_message(message) do
    user_id = fetch_user_by_phone(message.sender).id
    conversation_id = fetch_current_conversation(user_id).id

    params =
      %{conversation_id: conversation_id,
        user_id: user_id,
        text: message.text,
        timestamp: message.timestamp,
        uuid: message.uuid}
    changeset = Message.changeset(%Message{}, params)
    Storage.insert(changeset)
  end

  def insert_user(name, phone) do
    params = %{name: name, phone: phone}
    changeset = User.changeset(%User{}, params)

    Storage.insert(changeset)
  end

  def update_first_sms_relay_ip(ip) do
    first_sms_relay() |> change(ip: ip) |> Storage.update!
  end

  def refresh_sms_relay_ip(message) do
    Map.merge(message, %{sms_relay_ip: first_sms_relay().ip})
  end

  defp first_sms_relay do
    SMSRelay |> first |> Storage.one
  end

  defp fetch_user_by_phone(phone) do
    query = from User,
              where: [phone: ^phone],
              limit: 1

    Storage.one!(query)
  end

  defp fetch_current_conversation(user_id) do
    query = from Conversation,
              where: [left_user_id: ^user_id],
              or_where: [right_user_id: ^user_id],
              order_by: [desc: :start],
              limit: 1

    Storage.one!(query)
  end

  defp partner_id(conversation, user_id) do
    user_ids = [conversation.left_user_id, conversation.right_user_id]
    user_ids |> List.delete(user_id) |> List.first
  end

  defp fetch_user(user_id) do
    Storage.get!(User, user_id)
  end
end
