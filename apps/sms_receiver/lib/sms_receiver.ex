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
    update_sms_relay_ip(conn)
    send_resp(conn, 200, "")
  end

  post "/receive" do
    update_sms_relay_ip(conn)

    message = %SMSMessage{
      recipient: conn.params["recipient"],
      sender: conn.params["sender"],
      sms_relay_ip: remote_ip(conn),
      text: conn.params["text"],
      timestamp: to_datetime(conn.params["timestamp"]),
      uuid: conn.params["id"]}

    log_receipt(message)

    Router.handle(message)

    send_resp(conn, 200, "")
  end

  defp update_sms_relay_ip(conn) do
    Service.update_first_sms_relay_ip(remote_ip(conn))
  end

  defp remote_ip(conn) do
    conn.remote_ip |> Tuple.to_list |> Enum.join(".")
  end

  defp to_datetime(string) do
    {:ok, datetime, _} = DateTime.from_iso8601(string)
    datetime
  end

  defp log_receipt(message) do
    Logger.info("SMS received", [
      name: "SMSReceived",
      recipient: message.recipient,
      sender: message.sender,
      sms_relay_ip: message.sms_relay_ip,
      text: message.text,
      timestamp: message.timestamp,
      uuid: message.uuid])
  end
end
