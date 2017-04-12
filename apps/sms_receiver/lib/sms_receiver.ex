defmodule SMSReceiver do
  @moduledoc false

  use Plug.Router
  require Logger

  alias Core.Router

  plug :match
  plug :dispatch

  get "/receive" do
    conn = fetch_query_params(conn)

    id = conn.params["messageId"]
    recipient = conn.params["to"]
    sender = conn.params["msisdn"]
    text = conn.params["text"]
    timestamp = to_datetime(conn.params["message-timestamp"])

    log_receipt(id, recipient, sender, text, timestamp)

    message = %SMSMessage{
      recipient: recipient,
      sender: sender,
      text: text,
      timestamp: timestamp}

    Router.handle(message)

    send_resp(conn, 200, "")
  end

  defp to_datetime(string) do
    string_with_timezone = string <> "Z"

    {:ok, datetime, _} = DateTime.from_iso8601(string_with_timezone)
    datetime
  end

  defp log_receipt(id, recipient, sender, text, timestamp) do
    Logger.info("SMS received", [
      id: id,
      name: "SMSReceived",
      proxyPhone: recipient,
      sender: sender,
      text: text,
      timestamp: timestamp])
  end
end
