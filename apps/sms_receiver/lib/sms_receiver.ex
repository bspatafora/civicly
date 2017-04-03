defmodule SMSReceiver do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/receive" do
    conn = fetch_query_params(conn, [])

    message = %SMSMessage{
      recipient: param(conn, "to"),
      sender: param(conn, "msisdn"),
      text: param(conn, "text")}

    Core.Router.handle(message)

    send_resp(conn, 200, "")
  end

  defp param(conn, key) do
    conn.query_params[key]
  end
end
