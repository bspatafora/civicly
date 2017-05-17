defmodule SMSSender do
  @moduledoc false

  @spec send(SMSMessage.t) :: no_return()
  def send(message) do
    body = {:form, [
      recipient: message.recipient,
      text: message.text]}

    HTTPoison.post!(url(), body)
  end

  defp url do
    get_config(:origin) <> get_config(:path)
  end

  defp get_config(key) do
    Application.get_env(:sms_sender, key)
  end
end
