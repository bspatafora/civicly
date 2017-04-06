defmodule SMSReceiver do
  @moduledoc false

  use Plug.Router

  alias Core.Router

  plug :match
  plug :dispatch

  get "/receive" do
    conn = fetch_query_params(conn)

    message = %SMSMessage{
      recipient: conn.params["to"],
      sender: conn.params["msisdn"],
      text: conn.params["text"]}

    Router.handle(message)

    send_resp(conn, 200, "")
  end
end
