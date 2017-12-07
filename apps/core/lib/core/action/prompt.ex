defmodule Core.Action.Prompt do
  @moduledoc false

  alias Core.Sender
  alias Storage.Service
  alias Strings, as: S

  @data File.read!("lib/core/resources/prompts.txt")
  @prompts String.split(@data, "\n")

  def send(message) do
    prompt = S.prepend_civicly(Enum.random(@prompts))

    partner_phones = Service.partner_phones(message.sender)

    Sender.send_command_output(prompt, message)
    Sender.send_message(message.text, partner_phones, message)
    Sender.send_message(prompt, partner_phones, message)
  end
end
