defmodule Storage.Helpers do
  import Ecto.Query

  alias Ecto.UUID

  alias Storage.{Conversation, Message, RecentlyReceivedMessage, SMSRelay, User}

  def build_message(params \\ %{}) do
    message = %SMSMessage{
      recipient: random_phone(),
      sender: random_phone(),
      sms_relay_ip: "localhost",
      text: "Test message",
      timestamp: DateTime.utc_now(),
      uuid: uuid()}

    Map.merge(message, params)
  end

  def uuid do
    UUID.generate()
  end

  def random_phone do
    Integer.to_string(Enum.random(5_550_000_000..5_559_999_999))
  end

  def insert_conversation(params \\ %{}) do
    defaults =
      %{active?: false,
        iteration: 1,
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

  def insert_message(params \\ %{}) do
    defaults =
      %{text: "Test message",
        timestamp: DateTime.utc_now(),
        uuid: uuid()}
    changeset = Message.changeset(%Message{}, Map.merge(defaults, params))

    Storage.insert!(changeset)
  end

  def insert_recently_received_message(params \\ %{}) do
    defaults =
      %{sender: random_phone(),
        text: "Test message",
        timestamp: DateTime.utc_now()}
    params = Map.merge(defaults, params)
    changeset = RecentlyReceivedMessage.changeset(%RecentlyReceivedMessage{}, params)

    Storage.insert!(changeset)
  end

  def first_sms_relay_ip do
    sms_relay = SMSRelay |> first |> Storage.one
    sms_relay.ip
  end
end
