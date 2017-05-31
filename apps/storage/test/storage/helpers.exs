defmodule Storage.Helpers do
  alias Storage.{Conversation, User}

  def random_phone do
    Integer.to_string(Enum.random(5_550_000_000..5_559_999_999))
  end

  def insert_conversation(params \\ %{}) do
    defaults = %{
      left_user_id: insert_user().id,
      right_user_id: insert_user().id,
      proxy_phone: random_phone(),
      start: DateTime.utc_now}
    changeset = Conversation.changeset(%Conversation{}, Map.merge(defaults, params))

    {:ok, conversation} = Storage.insert(changeset)
    conversation
  end

  def insert_user(phone \\ random_phone()) do
    params = %{name: "Test User", phone: phone}
    changeset = User.changeset(%User{}, params)

    {:ok, user} = Storage.insert(changeset)
    user
  end
end
