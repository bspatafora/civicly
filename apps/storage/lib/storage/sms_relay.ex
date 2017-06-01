defmodule Storage.SMSRelay do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Storage.Conversation

  schema "sms_relays" do
    field :ip, :string
    field :phone, :string

    has_many :conversations, Conversation

    timestamps([type: :utc_datetime])
  end

  def changeset(sms_relay, params \\ %{}) do
    all_fields = [:ip, :phone]

    sms_relay
    |> cast(params, all_fields)
    |> validate_required(all_fields)
    |> validate_length(:ip, max: 45)
    |> validate_format(:phone, ~r/^\d{10}$/)
    |> unique_constraint(:phone)
  end
end
