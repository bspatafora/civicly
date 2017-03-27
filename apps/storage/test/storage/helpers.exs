defmodule Helpers do
  def random_phone do
    Integer.to_string(Enum.random(5550000000..5559999999))
  end
end
