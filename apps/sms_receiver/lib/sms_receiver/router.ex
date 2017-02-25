defmodule SMSReceiver.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/receive" do
    conn = fetch_query_params(conn, [])
    text = conn.query_params["text"]

    if text, do: SMSSender.send(text)

    send_resp(conn, 200, "")
  end
end
