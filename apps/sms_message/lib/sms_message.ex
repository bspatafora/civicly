defmodule SMSMessage do
  @moduledoc false

  @type t :: %__MODULE__{
    recipient: String.t,
    sender: String.t,
    sms_relay_ip: String.t,
    text: String.t,
    timestamp: DateTime.t,
    uuid: String.t}

  all_keys = [:recipient, :sender, :sms_relay_ip, :text, :timestamp, :uuid]
  @enforce_keys all_keys
  defstruct all_keys
end
