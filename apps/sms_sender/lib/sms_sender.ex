defmodule SMSSender do
  @moduledoc false

  @spec send(SMSMessage.t) :: no_return()
  def send(message) do
    body = Poison.encode!(%{
      recipient: message.recipient,
      text: message.text})

    headers = [{"Content-type", "application/json; charset=UTF-8"}]
    HTTPoison.post!(url(message.sms_relay_ip), body, headers)
  end

  defp url(host) do
    host <> ":" <> get_config(:port) <> get_config(:path)
  end

  defp get_config(key) do
    Application.get_env(:sms_sender, key)
  end
end
