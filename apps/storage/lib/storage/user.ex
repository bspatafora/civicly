defmodule Storage.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :phone, :string

    timestamps()
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
