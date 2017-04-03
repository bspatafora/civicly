defmodule SMSSender do
  @spec send(SMSMessage.t) :: no_return()
  def send(message) do
    body = {:form, [
      api_key: get_config(:api_key),
      api_secret: get_config(:api_secret),
      to: message.recipient,
      from: message.sender,
      text: message.text]}

    HTTPoison.post!(get_config(:url), body, [])
  end

  defp get_config(key) do
    Application.fetch_env!(:sms_sender, key)
  end
end
