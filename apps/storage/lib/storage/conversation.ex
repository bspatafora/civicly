defmodule Storage.Conversation do
  @moduledoc false

  import Ecto.Changeset
  use Ecto.Schema

  alias Storage.{Message, SMSRelay, User}

  schema "conversations" do
    field :iteration, :integer
    belongs_to :sms_relay, SMSRelay
    many_to_many :users, User, join_through: "conversations_users"

    has_many :messages, Message

    timestamps([type: :utc_datetime])
  end

  def changeset(conversation, params \\ %{}) do
    users = fetch_users(params)

    fields = [:iteration, :sms_relay_id]

    conversation
    |> Storage.preload(:users)
    |> cast(params, fields)
    |> validate_required(fields)
    |> validate_number(:iteration, greater_than: 0)
    |> foreign_key_constraint(:sms_relay_id)
    |> put_assoc(:users, users)
    |> validate_length(:users, min: 2)
  end

  defp fetch_users(params) do
    params = Map.merge(%{users: []}, params)

    params.users
    |> Enum.map(&(Storage.get(User, &1)))
    |> Enum.reject(&(&1 == nil))
  end
end
