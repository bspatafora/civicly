defmodule Storage.Service do
  @moduledoc false

  import Ecto.Query

  alias Storage.{Conversation, Message, User}

  def current_partner_and_proxy_phones(user_phone) do
    user_id = fetch_user_by_phone(user_phone).id
    conversation = fetch_current_conversation(user_id)

    partner_id = partner_id(conversation, user_id)
    partner = fetch_user(partner_id)

    {partner.phone, conversation.proxy_phone}
  end

  def store_message(message) do
    user_id = fetch_user_by_phone(message.sender).id
    conversation_id = fetch_current_conversation(user_id).id

    params =
      %{conversation_id: conversation_id,
        user_id: user_id,
        text: message.text,
        timestamp: message.timestamp}
    changeset = Message.changeset(%Message{}, params)
    Storage.insert(changeset)
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
