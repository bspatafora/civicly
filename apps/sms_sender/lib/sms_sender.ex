defmodule SMSSender do
  def send(text, recipient, proxy_phone) do
    body = {:form, [
      api_key: get_config(:api_key),
      api_secret: get_config(:api_secret),
      to: recipient,
      from: proxy_phone,
      text: text]}

    HTTPoison.post!(get_config(:url), body, [])
  end

  defp get_config(key) do
    Application.fetch_env!(:sms_sender, key)
  end
end
