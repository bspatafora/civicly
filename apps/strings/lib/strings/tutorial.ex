defmodule Strings.Tutorial do
  @moduledoc false

  import TrimNewlineSigil

  alias Strings, as: S

  def step_1 do
    ~n"""
    #{S.civicly()} Welcome to civicly! Please reply with the word "Go" to see how it works. This will only take a minute.

    Text "Help" at any time for help.
    """
  end

  def step_1_key do
    "go"
  end

  def step_1_error do
    "#{S.civicly()} Text the word \"Go\" to get started, or \"Help\" for more info."
  end

  def step_2_part_1 do
    ~n"""
    #{S.civicly()} civicly pairs Americans up for 1:1 conversations about our country.

    Each conversation lasts 4 days and happens right here.
    """
  end

  def step_2_part_2 do
    "#{S.civicly()} Text \"Example\" to see what it will look like when civicly starts a conversation for you."
  end

  def step_2_key do
    "example"
  end

  def step_2_error do
    "#{S.civicly()} Text the word \"Example\" to continue the tutorial, or \"Help\" for more info."
  end

  def step_3_part_1 do
    ~n"""
    #{S.civicly()} Now connected to Ben S, your compatriot for the next 4 days. Say hi!

    Here's a question to get you started: What is your favorite color?
    """
  end

  def step_3_part_2(name) do
    "Hey #{name}! I'd say orange. What about you?"
  end

  def step_3_part_3 do
    ~n"""
    #{S.civicly()} Note how your partner's message doesn't have [civicly] at the front, unlike system messages.

    Reply with your answer to continue the tutorial.
    """
  end

  def step_4_part_1 do
    ~n"""
    #{S.civicly()} Nice! Note: actual questions are more civic in nature ;)

    Once you're connected, texts you send to civicly will be delivered to your partner.
    """
  end

  def step_4_part_2 do
    ~n"""
    #{S.civicly()} Ok, just two more things!

    First: civicly only works if we listen to each other. Text "I will be civil" if you can commit to being civil.
    """
  end

  def step_4_key do
    "i will be civil"
  end

  def step_4_error do
    "#{S.civicly()} Text the phrase \"I will be civil\" to continue the tutorial, or \"Help\" for more info."
  end

  def step_5 do
    ~n"""
    #{S.civicly()} Excellent. Finally, please have a look at these:

    http://civicly.us/terms
    http://civicly.us/privacy

    Text "Accept" to agree, or "Help" for more info.
    """
  end

  def step_5_key do
    "accept"
  end

  def step_5_error do
    "#{S.civicly()} Text the word \"Accept\" to continue the tutorial, or \"Help\" for more info."
  end

  def complete_part_1 do
    "#{S.civicly()} Ok, we're all set! Now, just sit tight. You'll be connected to your first conversation partner within a few days."
  end

  def complete_part_2 do
    ~n"""
    #{S.civicly()} In the meantime, http://civicly.us/tips will help you get the most out of civicly.

    We're happy you're here!
    """
  end
end
