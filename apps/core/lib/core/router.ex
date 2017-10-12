defmodule Core.Router do
  @moduledoc false

  require Logger

  alias Core.Handler.{Command, HelpRequest, Missive, StopRequest, Tutorial}
  alias Strings, as: S

  @ben Application.get_env(:storage, :ben_phone)
  @storage Application.get_env(:core, :storage)

  def handle(message) do
    cond do
      command?(message) ->
        Command.handle(message)
      stop_request?(message) ->
        StopRequest.handle(message)
      help_request?(message) ->
        HelpRequest.handle(message)
      user?(message) ->
        handle_user(message)
      true ->
        log_unknown_sender(message)
    end
  end

  defp command?(message) do
    command? = String.starts_with?(message.text, S.command_prefix())
    message.sender == @ben && command?
  end

  defp stop_request?(message) do
    normalize(message.text) == S.stop_request()
  end

  defp help_request?(message) do
    normalize(message.text) == S.help_request()
  end

  defp normalize(string) do
    string
      |> String.trim
      |> String.upcase
  end

  defp user?(message) do
    @storage.user?(message.sender)
  end

  defp handle_user(message) do
    if @storage.in_tutorial?(message.sender) do
      Tutorial.handle(message)
    else
      Missive.handle(message)
    end
  end

  defp log_unknown_sender(message) do
    Logger.info("Unknown sender", [
      name: "UnknownSender",
      recipient: message.recipient,
      sender: message.sender,
      sms_relay_ip: message.sms_relay_ip,
      text: message.text,
      timestamp: message.timestamp,
      uuid: message.uuid])
  end
end
