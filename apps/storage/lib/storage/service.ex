defmodule Storage.Service do
  @moduledoc false

  import Ecto.Changeset
  import Ecto.Query

  alias Storage.{Message, SMSRelay, User}

  def partner_phones(user_phone) do
    user = fetch_user(user_phone)
    user = Storage.preload(user, :conversations)
    conversation = current_conversation(user)
    conversation = Storage.preload(conversation, :users)

    partner_phones(conversation, user.id)
  end

  def store_message(message) do
    user = fetch_user(message.sender)
    user = Storage.preload(user, :conversations)
    conversation = current_conversation(user)

    params =
      %{conversation_id: conversation.id,
        user_id: user.id,
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
    Map.put(message, :sms_relay_ip, first_sms_relay().ip)
  end

  def delete_user(phone) do
    user = Storage.get_by!(User, phone: phone)
    Storage.delete!(user)
  end

  def fetch_name(phone) do
    fetch_user(phone).name
  end

  defp first_sms_relay do
    SMSRelay |> first |> Storage.one
  end

  defp fetch_user(phone) do
    query = from User,
              where: [phone: ^phone],
              limit: 1

    Storage.one!(query)
  end

  defp current_conversation(user) do
    Enum.max_by(user.conversations, &(&1.iteration))
  end

  defp partner_phones(conversation, user_id) do
    conversation.users
      |> Enum.reject(&(&1.id == user_id))
      |> Enum.map(&(&1.phone))
  end
end
