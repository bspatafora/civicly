defmodule Helpers do
  def random_phone do
    base = Integer.to_string(Enum.random(5550000000..5559999999))
    "1#{base}"
  end
end
