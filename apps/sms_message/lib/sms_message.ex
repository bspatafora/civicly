defmodule SMSMessage do
  @moduledoc false

  @type t :: %__MODULE__{
    recipient: String.t,
    sender: String.t,
    text: String.t}

  @enforce_keys [:recipient, :sender, :text]
  defstruct [:recipient, :sender, :text]
end
