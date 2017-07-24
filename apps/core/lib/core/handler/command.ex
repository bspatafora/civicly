defmodule Core.Handler.Command do
  @moduledoc false

  alias Core.{CommandParser, Sender}

  @storage Application.get_env(:core, :storage)

  def handle(message) do
    case CommandParser.parse(message.text) do
      {:add, name, phone} ->
        attempt_user_insert(name, phone, message)
      {:invalid} ->
        Sender.send_command_output("Invalid command", message)
    end
  end

  defp attempt_user_insert(name, phone, message) do
    case @storage.insert_user(name, phone) do
      {:ok, user} ->
        Sender.send_command_output("Added #{user.name}", message)
      {:error, _} ->
        Sender.send_command_output("Insert failed", message)
    end
  end
end
