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
      sample_response_file = "test/core/api_client/sample_googl_response.txt"
      {:ok, response_body} = File.read(sample_response_file)
      Conn.resp(conn, 200, response_body)
    end

    assert Googl.shorten("http://example.com") == "http://goo.gl/fbsS"
  end
end
