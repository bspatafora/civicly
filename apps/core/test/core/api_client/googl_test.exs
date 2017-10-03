defmodule Core.APIClient.GooglTest do
  use ExUnit.Case

  alias Plug.Conn

  alias Core.APIClient.Googl

  setup do
    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "shorten/1 returns a shortened version of the URL", %{bypass: bypass} do
    Bypass.expect bypass, "POST", "/urlshortener/v1/url", fn conn ->
      response_body = File.read!("test/core/api_client/googl_response.txt")
      Conn.resp(conn, 200, response_body)
    end

    assert Googl.shorten("http://example.com") == "goo.gl/fbsS"
  end

  test "shorten/1 returns a shortened version of the URL when the goo.gl link is HTTPS", %{bypass: bypass} do
    Bypass.expect bypass, "POST", "/urlshortener/v1/url", fn conn ->
      response_body = File.read!("test/core/api_client/googl_response_https.txt")
      Conn.resp(conn, 200, response_body)
    end

    assert Googl.shorten("http://example.com") == "goo.gl/fbsS"
  end
end
