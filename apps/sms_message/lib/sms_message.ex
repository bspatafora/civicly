defmodule SMSMessage do
  @moduledoc false

  @type t :: %__MODULE__{
    recipient: String.t,
    sender: String.t,
    text: String.t,
    timestamp: DateTime.t}

  all_keys = [:recipient, :sender, :text, :timestamp]
  @enforce_keys all_keys
  defstruct all_keys
end
