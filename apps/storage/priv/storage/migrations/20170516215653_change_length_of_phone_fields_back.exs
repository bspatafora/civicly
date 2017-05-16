defmodule Storage.Migrations.ChangeLengthOfPhoneFieldsBack do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :phone, :string, size: 10
    end

    alter table(:conversations) do
      modify :proxy_phone, :string, size: 10
    end
  end
end
