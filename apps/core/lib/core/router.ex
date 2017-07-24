defmodule Core.Router do
  @moduledoc false

  alias Core.Handler.{Command, Missive, StopRequest}

  @ben Application.get_env(:storage, :ben_phone)

  @spec handle(SMSMessage.t) :: no_return()
  def handle(message) do
    cond do
      command?(message) ->
        Command.handle(message)
      stop_request?(message) ->
        StopRequest.handle(message)
      true ->
        Missive.handle(message)
    end
  end

  defp command?(message) do
    from_ben? = message.sender == @ben
    command? = String.starts_with?(message.text, ":")

    from_ben? && command?
  end

  defp stop_request?(message) do
    String.downcase(message.text) == "stop"
  end
end
