defmodule Storage.Conversation do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Storage.{Message, SMSRelay, User}

  schema "conversations" do
    belongs_to :left_user, User
    belongs_to :right_user, User
    belongs_to :sms_relay, SMSRelay

    field :start, :utc_datetime

    has_many :messages, Message

    timestamps([type: :utc_datetime])
  end

  def changeset(conversation, params \\ %{}) do
    all_fields = [:left_user_id, :right_user_id, :sms_relay_id, :start]

    conversation
    |> cast(params, all_fields)
    |> validate_required(all_fields)
    |> foreign_key_constraint(:left_user_id)
    |> foreign_key_constraint(:right_user_id)
    |> foreign_key_constraint(:sms_relay_id)
    |> exclusion_constraint(:one_per_user_per_time, [name: "one_per_user_per_time"])
    |> check_constraint(:different_user_ids, [name: "different_user_ids"])
  end
end
