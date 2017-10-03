defmodule Core.APIClient.APIClient do
  @moduledoc false

  @ssl_fix [ssl: [{:versions, [:"tlsv1.2"]}]]

  def get!(url) do
    response = HTTPoison.get!(url, [], @ssl_fix)

    Poison.decode!(response.body)
  end

  def post!(url, body) do
    headers = ["Content-Type": "application/json"]
    body = Poison.encode!(body)
    response = HTTPoison.post!(url, body, headers, @ssl_fix)

    Poison.decode!(response.body)
  end
end
