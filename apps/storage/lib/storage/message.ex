defmodule Storage.Message do
  @moduledoc false

  import Ecto.Changeset
  use Ecto.Schema

  alias Storage.{Conversation, User}

  schema "messages" do
    belongs_to :conversation, Conversation
    belongs_to :user, User

    field :text, :string
    field :timestamp, :utc_datetime
    field :uuid, Ecto.UUID

    timestamps([type: :utc_datetime])
  end

  def changeset(message, params \\ %{}) do
    all_fields = [:conversation_id, :user_id, :text, :timestamp, :uuid]

    message
    |> cast(params, all_fields)
    |> validate_required(all_fields)
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:user_id)
  end
end
