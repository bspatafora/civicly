defmodule Storage.Service do
  @moduledoc false

  alias Storage.Service.{Conversation, Message, User}

  def partner_phones(phone) do
    conversation = current_conversation(phone)
    Conversation.partner_phones(phone, conversation)
  end

  def store_message(message) do
    user = User.by_phone(message.sender)
    conversation = current_conversation(user)

    Message.insert(message, user.id, conversation.id)
  end

  def in_conversation?(phone) do
    user = User.by_phone(phone)
    user = Storage.preload(user, :conversations)

    if Enum.empty?(user.conversations) do
      false
    else
      conversation = current_conversation(user)
      Conversation.active?(conversation)
    end
  end

  def inactivate_current_conversation(phone) do
    conversation = current_conversation(phone)
    Conversation.inactivate(conversation)
  end

  def all_phones do
    User.all()
      |> Enum.map(&(&1.phone))
  end

  def active_phones do
    Conversation.all_active()
      |> Enum.map(&(&1.users))
      |> List.flatten
      |> Enum.map(&(&1.phone))
  end

  def not_yet_engaged_phones do
    active_conversations = Conversation.all_active()

    active_users = active_conversations
      |> Enum.map(&(&1.users))
      |> List.flatten

    engaged_user_ids = active_conversations
      |> Enum.map(&(Storage.preload(&1, :messages)))
      |> Enum.map(&(&1.messages))
      |> List.flatten
      |> Enum.map(&(&1.user_id))
      |> Enum.dedup

    active_users
      |> Enum.reject(&(Enum.member?(engaged_user_ids, &1.id)))
      |> Enum.map(&(&1.phone))
  end

  defp current_conversation(user) when is_map(user) do
    user = Storage.preload(user, :conversations)
    Enum.max_by(user.conversations, &(&1.iteration))
  end

  defp current_conversation(phone) do
    user = User.by_phone(phone)
    current_conversation(user)
  end
end
