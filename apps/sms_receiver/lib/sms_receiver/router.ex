defmodule SMSReceiver.Router do
  use Plug.Router
  require Logger

  plug :match
  plug :dispatch

  get "/receive" do
    send_resp(conn, 200, "")

    conn = fetch_query_params(conn, [])
    text = param(conn, "text")
    sender = param(conn, "msisdn")

    Logger.info("SMS received", [
      name: "SMSReceiver.Router.SMSReceived",
      smsID: param(conn, "messageId"),
      smsRecipient: param(conn, "to"),
      smsSender: sender,
      smsText: text,
      smsTime: param(conn, "message-timestamp")])

    {recipient, proxy_phone} = fetch_recipient_and_proxy_phones(sender)
    SMSSender.send(text, recipient, proxy_phone)
  end

  defp param(conn, key) do
    conn.query_params[key]
  end

  defp fetch_recipient_and_proxy_phones(sender) do
    Storage.Service.current_partner_and_proxy_phones(sender)
  end
end
