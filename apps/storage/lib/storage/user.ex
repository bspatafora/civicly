defmodule Storage.User do
  @moduledoc false

  import Ecto.Changeset
  use Ecto.Schema

  alias Storage.{Conversation, Message}

  schema "users" do
    field :name, :string
    field :phone, :string
    field :tutorial_step, :integer, default: 0
    field :engagement_level, :integer, default: -1

    many_to_many :conversations, Conversation, join_through: "conversations_users"
    has_many :messages, Message

    timestamps([type: :utc_datetime])
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:name, :phone, :tutorial_step, :engagement_level])
    |> validate_required([:name, :phone])
    |> validate_length(:name, max: 100)
    |> validate_format(:phone, ~r/^\d{10}$/)
    |> unique_constraint(:phone)
  end
end
