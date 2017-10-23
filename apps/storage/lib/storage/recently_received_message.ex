defmodule Storage.RecentlyReceivedMessage do
  @moduledoc false

  import Ecto.Changeset
  use Ecto.Schema

  schema "recently_received_messages" do
    field :sender, :string
    field :text, :string
    field :timestamp, :utc_datetime

    timestamps([type: :utc_datetime])
  end

  def changeset(recently_received_message, params \\ %{}) do
    all_fields = [:sender, :text, :timestamp]

    recently_received_message
    |> cast(params, all_fields)
    |> validate_required(all_fields)
  end
end
