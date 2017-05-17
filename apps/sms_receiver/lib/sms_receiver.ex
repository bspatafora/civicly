defmodule SMSReceiver do
  @moduledoc false

  use Plug.Router
  require Logger

  alias Core.Router

  plug Plug.Parsers, parsers: [:json], json_decoder: Poison
  plug :match
  plug :dispatch

  post "/sms_relay_heartbeat" do
    send_resp(conn, 200, "")
  end

  post "/receive" do
    id = conn.params["id"]
    recipient = conn.params["recipient"]
    sender = conn.params["sender"]
    text = conn.params["text"]
    timestamp = to_datetime(conn.params["timestamp"])

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
    {:ok, datetime, _} = DateTime.from_iso8601(string)
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
