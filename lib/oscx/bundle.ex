defmodule OSCx.Bundle do
  @moduledoc """
  A module and struct for manipulating and representing OSC bundles.

  The struct has two keys:
  - `time:` a map representing an OSC time tag
  - `elements:` an Elixir list of Messages or Bundles.

  ## About OSC bundles
  Bundles are a way of grouping OSC messages and even other OSC bundles together, so they can be recieved by the OSC server simultaneously.

  ### Structure of an OSC bundle
  A bundle is made up of three parts:
  - Bundle identifer: which is the the string “#bundle”.
  - Time: a time tag which is a 64-bit time identifier. The first 32 bits specify the number of seconds since midnight on January 1, 1900, and the last 32 bits specify fractional parts of a second to a precision of about 200 picoseconds. This representation is used by Internet NTP timestamps.
  - Elements: the payload of the bundle, which can be any number of messages or bundles. Each of these are preceded by a 4-byte integer byte count.

  ![OSC bundle diagram](assets/osc-bundle.png)

  """

  defstruct time: %{seconds: nil, fraction: nil}, elements: []
  alias OSCx.Encoder

  def encode(time, elements) do
    [
      "#bundle",
      0,
      Encoder.time(time),
      elements
    ]
  end

  # defp encode_elements(elements) do
  #   for element <- elements do
  #     element
  #     |> OSC.Encoder.encode()
  #     |> OSC.Encoder.prefix_size()
  #   end
  # end

  def decode(binary_message) do
    binary_message
  end

  def encode(bundle) when is_struct(bundle, OSCx.Bundle) do
    bundle
  end

end
