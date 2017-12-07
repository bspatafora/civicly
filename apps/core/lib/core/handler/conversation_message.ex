defmodule Core.Handler.ConversationMessage do
  @moduledoc false

  alias Core.Action.Prompt
  alias Core.Handler.Tutorial
  alias Core.Sender
  alias Storage.Service
  alias Storage.Service.User
  alias Strings, as: S

  def handle(message) do
    cond do
      tutorial?(message) ->
        Tutorial.handle(message)
      active_conversation?(message) ->
        handle_active_conversation(message)
      true ->
        handle_no_conversation(message)
    end
  end

  defp tutorial?(message) do
    User.in_tutorial?(message.sender)
  end

  defp active_conversation?(message) do
    in_conversation? = Service.in_conversation?(message.sender)

    in_conversation? && Enum.any?(Service.partner_phones(message.sender))
  end

  defp prompt_request?(message) do
    text = message.text |> String.trim |> String.upcase

    text == S.prompt_request()
  end

  defp handle_active_conversation(message) do
    if prompt_request?(message) do
      Prompt.send(message)
    else
      store_and_relay(message)
    end
  end

  defp store_and_relay(message) do
    Service.store_message(message)

    partner_phones = Service.partner_phones(message.sender)
    Sender.send_message(message.text, partner_phones, message)
  end

  defp handle_no_conversation(message) do
    Sender.send_command_output(S.empty_room(), message)
  end
end
