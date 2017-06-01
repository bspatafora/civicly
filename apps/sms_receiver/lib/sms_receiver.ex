defmodule SMSReceiver do
  @moduledoc false

  use Plug.Router
  require Logger

  alias Core.Router
  alias Storage.Service

  plug Plug.Parsers, parsers: [:json], json_decoder: Poison
  plug :match
  plug :dispatch

  post "/sms_relay_heartbeat" do
    sms_relay_ip = conn.remote_ip |> Tuple.to_list |> Enum.join(".")

    Service.update_first_sms_relay_ip(sms_relay_ip)

    send_resp(conn, 200, "")
  end

  post "/receive" do
    id = conn.params["id"]
    recipient = conn.params["recipient"]
    sender = conn.params["sender"]
    sms_relay_ip = conn.remote_ip |> Tuple.to_list |> Enum.join(".")
    text = conn.params["text"]
    timestamp = to_datetime(conn.params["timestamp"])

    log_receipt(id, recipient, sender, sms_relay_ip, text, timestamp)

    message = %SMSMessage{
      recipient: recipient,
      sender: sender,
      sms_relay_ip: sms_relay_ip,
      text: text,
      timestamp: timestamp}

    Router.handle(message)

    send_resp(conn, 200, "")
  end

  defp to_datetime(string) do
    {:ok, datetime, _} = DateTime.from_iso8601(string)
    datetime
  end

  defp log_receipt(id, recipient, sender, sms_relay_ip, text, timestamp) do
    Logger.info("SMS received", [
      id: id,
      name: "SMSReceived",
      recipient: recipient,
      sender: sender,
      sms_relay_ip: sms_relay_ip,
      text: text,
      timestamp: timestamp])
  end
end
