defmodule Strings.Tutorial do
  @moduledoc false

  alias Strings, as: S

  def step_1_part_1(name) do
    "#{S.civicly()} Welcome to civicly, #{name}! Thanks for joining your fellow Americans in making a habit out of civic conversation."
  end

  def step_1_part_2 do
    """
    #{S.civicly()} Let's get started!

    You interact with civicly entirely via text. Go ahead and reply to this text with the word "Begin" to continue.
    """
  end

  def step_1_key do
    "begin"
  end

  def step_1_error do
    "#{S.civicly()} Text the word \"Begin\" to continue the tutorial, or \"Help\" for help."
  end

  def step_2_part_1 do
    """
    #{S.civicly()} civicly pairs Americans up for 1:1 conversations about our country.

    Each conversation lasts for 4 days and happens right here.
    """
  end

  def step_2_part_2 do
    """
    #{S.civicly()} Let's see what it looks like when you're connected to someone.

    Text "Ready" to see the example. Once you get it, reply with your answer to continue.
    """
  end

  def step_2_key do
    "ready"
  end

  def step_2_error do
    "#{S.civicly()} Text the word \"Ready\" to continue the tutorial, or \"Help\" for help."
  end

  def step_3_part_1 do
    """
    #{S.civicly()} Now connected to Ben S, your compatriot for the next 4 days.

    Here's a question to get you started: What's your favorite color?
    """
  end

  def step_3_part_2(name) do
    """
    Hi, #{name}! My favorite color is probably green. You?

    (Note how this message DIDN'T start with [civicly], since I'm your conversation partner.)
    """
  end

  def step_4_part_1 do
    """
    #{S.civicly()} Nice! Note that a real question would be more civic in nature ;)

    Once you're connected to someone, texts you send will be delivered to your partner.
    """
  end

  def step_4_part_2 do
    """
    #{S.civicly()} Ok, just a few more things.

    First: civicly only works if we actually listen to each other! Text "I will be civil" if you can commit to be civil.
    """
  end

  def step_4_key do
    "i will be civil"
  end

  def step_4_error do
    "#{S.civicly()} Text the phrase \"I will be civil\" to continue the tutorial, or \"Help\" for help."
  end

  def step_5 do
    "#{S.civicly()} Excellent. You also must agree to civicly.us/terms and civicly.us/privacy to use civicly. Text \"I agree\" if you agree."
  end

  def step_5_key do
    "i agree"
  end

  def step_5_error do
    "#{S.civicly()} Text the phrase \"I agree\" to continue the tutorial, or \"Help\" for help."
  end

  def complete_part_1 do
    "#{S.civicly()} Ok, we're all set! Now, just sit tight. You'll be connected with your first conversation partner in the next few days."
  end

  def complete_part_2 do
    """
    #{S.civicly()} In the meantime, civicly.us/tips will help you get the most out of civicly. We're happy you're here!

    Text "Help" at any time for help.
    """
  end
end
