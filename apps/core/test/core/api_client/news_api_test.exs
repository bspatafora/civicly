defmodule Core.APIClient.NewsAPITest do
  use ExUnit.Case

  alias Plug.Conn

  alias Core.APIClient.NewsAPI

  setup do
    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "reuters_top/0 returns the title and URL of the current top Reuters story (excluding special reports)", %{bypass: bypass} do
    Bypass.expect bypass, "GET", "/v1/articles", fn conn ->
      response_body = File.read!("test/core/api_client/news_api_response.txt")
      Conn.resp(conn, 200, response_body)
    end

    {title, url} = NewsAPI.reuters_top

    assert title == "After victory in Raqqa over IS, Kurds face tricky peace"
    assert url == "https://www.reuters.com/article/us-mideast-crisis-syria-raqqa-future-ana/after-victory-in-raqqa-over-is-kurds-face-tricky-peace-idUSKBN1CM2C6"
  end
end
