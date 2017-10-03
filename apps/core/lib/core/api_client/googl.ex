defmodule Core.APIClient.Googl do
  @moduledoc false

  alias Core.APIClient.APIClient

  def shorten(long_url) do
    key = get_config(:googl_key)
    path = "/urlshortener/v1/url?key=#{key}"
    url = get_config(:googl_origin) <> path
    body = %{longUrl: long_url}

    response_body = APIClient.post!(url, body)

    get_short_url(response_body)
  end

  defp get_config(key) do
    Application.get_env(:core, key)
  end

  defp get_short_url(response_body) do
    short_url = Map.fetch!(response_body, "id")
    remove_protocol(short_url)
  end

  defp remove_protocol(url) do
    url
      |> String.replace_prefix("http://", "")
      |> String.replace_prefix("https://", "")
  end
end
