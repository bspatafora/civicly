defmodule Storage.Service.Message do
  @moduledoc false

  alias Storage.Message

  def insert(message, user_id, conversation_id) do
    params =
      %{conversation_id: conversation_id,
        user_id: user_id,
        text: message.text,
        timestamp: message.timestamp,
        uuid: message.uuid}

    changeset = Message.changeset(%Message{}, params)
    Storage.insert(changeset)
  end
end
