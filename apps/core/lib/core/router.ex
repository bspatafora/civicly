defmodule Core.Router do
  @moduledoc false

  alias Core.Handler.{Command, HelpRequest, Missive, StopRequest}
  alias Strings, as: S

  @ben Application.get_env(:storage, :ben_phone)

  @spec handle(SMSMessage.t) :: no_return()
  def handle(message) do
    cond do
      command?(message) ->
        Command.handle(message)
      stop_request?(message) ->
        StopRequest.handle(message)
      help_request?(message) ->
        HelpRequest.handle(message)
      true ->
        Missive.handle(message)
    end
  end

  defp command?(message) do
    from_ben? = message.sender == @ben
    command? = String.starts_with?(message.text, S.command_prefix())

    from_ben? && command?
  end

  defp stop_request?(message) do
    message.text == S.stop_request()
  end

  defp help_request?(message) do
    String.upcase(message.text) == S.help_request()
  end
end
