defmodule TrimNewlineSigil do
  @moduledoc false

  def sigil_n(string, []), do: String.trim_trailing(string, "\n")
end
