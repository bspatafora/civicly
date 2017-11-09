defmodule Storage.CommandHistory do
  @moduledoc false

  import Ecto.Changeset
  use Ecto.Schema

  schema "command_history" do
    field :text, :string
    field :timestamp, :utc_datetime

    timestamps([type: :utc_datetime])
  end

  def changeset(command_history, params \\ %{}) do
    all_fields = [:text, :timestamp]

    command_history
    |> cast(params, all_fields)
    |> validate_required(all_fields)
  end
end
