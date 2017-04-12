defmodule Storage.Message do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Storage.{Conversation, User}

  schema "messages" do
    belongs_to :conversation, Conversation
    belongs_to :user, User

    field :text, :string
    field :timestamp, :utc_datetime

    timestamps([type: :utc_datetime])
  end

  def changeset(message, params \\ %{}) do
    all_fields = [:conversation_id, :user_id, :text, :timestamp]

    message
    |> cast(params, all_fields)
    |> validate_required(all_fields)
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:user_id)
  end
end
