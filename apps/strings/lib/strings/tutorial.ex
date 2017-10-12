defmodule Strings.Tutorial do
  @moduledoc false

  def step_1_part_1(name) do
    "Welcome to civicly, #{name}! Thanks for joining your fellow Americans in making a habit out of civic conversation."
  end

  def step_1_part_2 do
    "Let's get started! You interact with civicly entirely via text. Go ahead and reply to this text with the word \"Next\" to continue."
  end

  def step_1_key do
    "next"
  end

  def step_1_error do
    "Text the word \"Next\" to continue the tutorial, or \"Help\" for help."
  end

  def step_2_part_1 do
    "civicly pairs Americans up for 1:1 conversations about our country. Each conversation lasts for 4 days and happens right here."
  end

  def step_2_part_2 do
    "Let's see what happens when you're connected to someone. Text \"Ready\" to see the example. Once you receive it, reply with your answer to continue."
  end

  def step_2_key do
    "ready"
  end

  def step_2_error do
    "Text \"Ready\" to continue the tutorial, or \"Help\" for help."
  end

  def step_3 do
    """
    Now connected to Ben S, your compatriot for the next 4 days.

    Here's a question to get you started: What's your favorite color?
    """
  end

  def step_4_part_1 do
    "Nice! If this were the real deal, the question would be a bit more civic in nature, and you'd probably want to say hi to your partner first."
  end

  def step_4_part_2 do
    "Ok, just a few more things. First: civicly only works if we actually listen to each other. Text \"I agree\" if you commit to be civil."
  end

  def step_4_key do
    "i agree"
  end

  def step_4_error do
    "Text \"I agree\" to continue the tutorial, or \"Help\" for help."
  end

  def step_5 do
    "Excellent. You also must agree to civicly.us/terms and civicly.us/privacy to use civicly. Text \"I agree\" if you agree."
  end

  def step_5_key do
    step_4_key()
  end

  def step_5_error do
    step_4_error()
  end

  def complete_part_1 do
    "Ok, we're all set! Now, just sit tight. You'll be connected with your first conversation partner in the next few days."
  end

  def complete_part_2 do
    "In the meantime, civicly.us/tips will help you get the most out of civicly. We're happy to have you!"
  end
end
