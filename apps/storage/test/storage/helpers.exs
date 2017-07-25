defmodule Storage.Helpers do
  import Ecto.Query

  alias Ecto.UUID

  alias Storage.{Conversation, SMSRelay, User}

  def uuid do
    UUID.generate()
  end

  def random_phone do
    Integer.to_string(Enum.random(5_550_000_000..5_559_999_999))
  end

  def insert_conversation(params \\ %{}) do
    defaults =
      %{iteration: 1,
        sms_relay_id: insert_sms_relay().id,
        users: [insert_user().id, insert_user().id]}

    changeset =
      Conversation.changeset(%Conversation{}, Map.merge(defaults, params))

    {:ok, conversation} = Storage.insert(changeset)
    Storage.preload(conversation, :sms_relay)
  end

  def insert_user(params \\ %{}) do
    defaults =
      %{name: "Test User",
        phone: random_phone()}
    changeset = User.changeset(%User{}, Map.merge(defaults, params))

    {:ok, user} = Storage.insert(changeset)
    user
  end

  def insert_sms_relay(params \\ %{}) do
    defaults =
      %{ip: "localhost",
        phone: random_phone()}
    changeset = SMSRelay.changeset(%SMSRelay{}, Map.merge(defaults, params))

    {:ok, sms_relay} = Storage.insert(changeset)
    sms_relay
  end

  def first_sms_relay_ip do
    sms_relay = SMSRelay |> first |> Storage.one
    sms_relay.ip
  end
end
