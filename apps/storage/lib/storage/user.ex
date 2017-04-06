defmodule Storage.User do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Storage.Conversation

  schema "users" do
    field :name, :string
    field :phone, :string

    has_many :left_conversations, Conversation, foreign_key: :left_user_id
    has_many :right_conversations, Conversation, foreign_key: :right_user_id

    timestamps([type: :utc_datetime])
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:name, :phone])
    |> validate_required([:name, :phone])
    |> validate_length(:name, max: 100)
    |> validate_format(:phone, ~r/^\d{11}$/)
    |> unique_constraint(:phone)
  end
end
