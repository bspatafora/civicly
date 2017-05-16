defmodule Helpers do
  def random_phone do
    Integer.to_string(Enum.random(5_550_000_000..5_559_999_999))
  end
end
