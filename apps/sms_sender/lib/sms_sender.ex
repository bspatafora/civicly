defmodule SMSSender do
  def send(text) do
    url = "https://rest.nexmo.com/sms/json"
    body = {:form, [
      api_key: "1f55a721",
      api_secret: "02de69d6e2fb67cA",
      to: "16306326718",
      from: "16303200120",
      text: text]}

    HTTPoison.post!(url, body, [])
  end
end
