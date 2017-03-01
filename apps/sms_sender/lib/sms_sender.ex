defmodule SMSSender do
  def send(text) do
    body = {:form, [
      api_key: api_key(),
      api_secret: api_secret(),
      to: "16306326718",
      from: "16303200120",
      text: text]}

    HTTPoison.post!(url(), body, [])
  end

  defp url do
    get_config(:url)
  end

  defp api_key do
    get_config(:api_key)
  end

  defp api_secret do
    get_config(:api_secret)
  end

  defp get_config(key) do
    Application.fetch_env!(:sms_sender, key)
  end
end
