defmodule Storage.Conversation do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Storage.User

  schema "conversations" do
    belongs_to :left_user, User
    belongs_to :right_user, User

    field :proxy_phone, :string
    field :start, :utc_datetime

    timestamps([type: :utc_datetime])
  end

  def changeset(conversation, params \\ %{}) do
    conversation
    |> cast(params, [:left_user_id, :right_user_id, :proxy_phone, :start])
    |> validate_required([:left_user_id, :right_user_id, :proxy_phone, :start])
    |> validate_format(:proxy_phone, ~r/^\d{11}$/)
    |> foreign_key_constraint(:left_user_id)
    |> foreign_key_constraint(:right_user_id)
    |> exclusion_constraint(:one_per_user_per_time, [name: "one_per_user_per_time"])
    |> check_constraint(:different_user_ids, [name: "different_user_ids"])
  end
end
