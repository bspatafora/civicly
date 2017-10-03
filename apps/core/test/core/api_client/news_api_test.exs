defmodule Core.APIClient.NewsAPITest do
  use ExUnit.Case

  alias Plug.Conn

  alias Core.APIClient.NewsAPI

  setup do
    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "ap_top/0 returns the title and URL of the current top AP story", %{bypass: bypass} do
    Bypass.expect bypass, "GET", "/v1/articles", fn conn ->
      sample_response_file = "test/core/api_client/sample_news_api_response.txt"
      {:ok, response_body} = File.read(sample_response_file)
      Conn.resp(conn, 200, response_body)
    end

    {title, url} = NewsAPI.ap_top

    assert title == "Sniper in high-rise hotel kills at least 58 in Las Vegas"
    assert url == "https://apnews.com/4eeaef2efced49698855d13830de3327"
  end
end
