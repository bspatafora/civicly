defmodule Storage.Service do
  @moduledoc false

  import Ecto.Changeset
  import Ecto.Query

  alias Storage.{Conversation, Message, SMSRelay, User}

  def partner_phones(user_phone) do
    user = user(user_phone)
    user = Storage.preload(user, :conversations)
    conversation = current_conversation(user)
    conversation = Storage.preload(conversation, :users)

    partner_phones(conversation, user.id)
  end

  def store_message(message) do
    user = user(message.sender)
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

  def first_sms_relay do
    SMSRelay |> first |> Storage.one
  end

  def current_conversations do
    query = from Conversation,
              where: [iteration: ^current_iteration()],
              preload: [:sms_relay, :users]
    Storage.all(query)
  end

  def current_iteration do
    query = from c in Conversation, select: max(c.iteration)
    Storage.one(query)
  end

  def active_conversation?(user_phone) do
    user = user(user_phone)
    user = Storage.preload(user, :conversations)

    if Enum.empty?(user.conversations) do
      false
    else
      current_conversation(user).active?
    end
  end

  def activate(conversation) do
    params =
      %{active?: true,
        users: Enum.map(conversation.users, &(&1.id))}

    conversation
      |> Conversation.changeset(params)
      |> Storage.update!
  end

  def inactivate_all_conversations do
    Storage.update_all(Conversation, set: [active?: false])
  end

  def all_phones do
    all_users = Storage.all(User)
    Enum.map(all_users, &(&1.phone))
  end

  defp user(phone) do
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
