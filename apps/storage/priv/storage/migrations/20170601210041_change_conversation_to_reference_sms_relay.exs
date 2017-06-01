defmodule Storage.Migrations.ChangeConversationToReferenceSMSRelay do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      remove :proxy_phone
      add :sms_relay_id, references(:sms_relays), null: false
    end
  end
end
