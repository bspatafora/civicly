defmodule Storage.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :phone, :string

    has_many :left_conversations, Storage.Conversation, foreign_key: :left_user_id
    has_many :right_conversations, Storage.Conversation, foreign_key: :right_user_id

    timestamps([type: :utc_datetime])
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:name, :phone])
    |> validate_required([:name, :phone])
    |> validate_length(:name, max: 100)
    |> validate_format(:phone, ~r/^\d{10}$/)
    |> unique_constraint(:phone)
  end
end
