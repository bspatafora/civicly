defmodule Storage.Service do
  import Ecto.Query

  def current_partner_and_proxy_phones(user_phone) do
    user_id = fetch_user_by_phone(user_phone).id
    conversation = fetch_current_conversation(user_id)

    partner_id = partner_id(conversation, user_id)
    partner = fetch_user(partner_id)

    {partner.phone, conversation.proxy_phone}
  end

  defp fetch_user_by_phone(phone) do
    query = from Storage.User,
              where: [phone: ^phone],
              limit: 1

    Storage.one!(query)
  end

  defp fetch_current_conversation(user_id) do
    query = from Storage.Conversation,
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
    Storage.get!(Storage.User, user_id)
  end
end
