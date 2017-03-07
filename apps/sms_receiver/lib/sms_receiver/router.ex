defmodule SMSReceiver.Router do
  use Plug.Router
  require Logger

  plug :match
  plug :dispatch

  get "/receive" do
    conn = fetch_query_params(conn, [])
    text = param(conn, "text")

    Logger.info("SMS received", [
      name: "SMSReceiver.Router.SMSReceived",
      smsID: param(conn, "messageId"),
      smsRecipient: param(conn, "to"),
      smsSender: param(conn, "msisdn"),
      smsText: text,
      smsTime: param(conn, "message-timestamp")])

    SMSSender.send(text)

    send_resp(conn, 200, "")
  end

  defp param(conn, key) do
    conn.query_params[key]
  end
end
