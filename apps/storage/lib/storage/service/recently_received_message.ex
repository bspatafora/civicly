defmodule Storage.Service.RecentlyReceivedMessage do
  @moduledoc false

  import Ecto.Query

  alias Storage.RecentlyReceivedMessage

  def duplicate?(message) do
    purge_recently_received_messages()

    query = from RecentlyReceivedMessage,
              where: [sender: ^message.sender, text: ^message.text]
    duplicates = Storage.all(query)

    Enum.any?(duplicates)
  end

  def insert(message) do
    params =
      %{sender: message.sender,
        text: message.text,
        timestamp: message.timestamp}
    changeset = RecentlyReceivedMessage.changeset(%RecentlyReceivedMessage{}, params)

    Storage.insert(changeset)
  end

  defp purge_recently_received_messages do
    unix_now = DateTime.to_unix(DateTime.utc_now())
    unix_five_minutes_ago = unix_now - 300
    five_minutes_ago = DateTime.from_unix!(unix_five_minutes_ago)
    delete_query = from m in RecentlyReceivedMessage,
                     where: m.timestamp < ^five_minutes_ago
    Storage.delete_all(delete_query)
  end
end
