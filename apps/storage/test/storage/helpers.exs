defmodule Helpers do
  def random_phone do
    base = Integer.to_string(Enum.random(5_550_000_000..5_559_999_999))
    "1#{base}"
  end
end
