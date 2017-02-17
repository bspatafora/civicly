defmodule SMSReceiver.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/hello" do
    IO.inspect(conn)
    send_resp(conn, 200, "")
  end
end
