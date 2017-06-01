defmodule Storage.Migrations.CreateSMSRelays do
  use Ecto.Migration

  def change do
    create table(:sms_relays) do
      add :ip, :string, null: false, size: 45
      add :phone, :string, null: false, size: 10

      timestamps([type: :utc_datetime])
    end

    create unique_index(:sms_relays, [:phone])
  end
end
