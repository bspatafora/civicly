defmodule Storage.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :phone, :string

    belongs_to :partner, __MODULE__
    has_one :user, __MODULE__, foreign_key: "partner_id"

    timestamps()
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:name, :phone, :partner_id])
    |> validate_required([:name, :phone])
    |> validate_length(:name, max: 100)
    |> validate_format(:phone, ~r/^\d{10}$/)
    |> unique_constraint(:phone)
    |> unique_constraint(:partner_id)
    |> foreign_key_constraint(:partner_id)
  end
end
