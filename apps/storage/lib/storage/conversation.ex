defmodule Storage.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversations" do
    belongs_to :left_user, Storage.User
    belongs_to :right_user, Storage.User

    field :proxy_phone, :string
    field :start, :utc_datetime

    timestamps([type: :utc_datetime])
  end

  def changeset(conversation, params \\ %{}) do
    conversation
    |> cast(params, [:left_user_id, :right_user_id, :proxy_phone, :start])
    |> validate_required([:left_user_id, :right_user_id, :proxy_phone, :start])
    |> validate_format(:proxy_phone, ~r/^\d{10}$/)
    |> foreign_key_constraint(:left_user_id)
    |> foreign_key_constraint(:right_user_id)
    |> exclusion_constraint(:one_per_user_per_time, [name: "one_per_user_per_time"])
    |> check_constraint(:different_user_ids, [name: "different_user_ids"])
  end
end
