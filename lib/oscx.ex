defmodule OSCx do
  @moduledoc """
  This is the main OSCx module.

  OSCx is an Elixir library for encoding and decoding Open Sound Control (OSC) messages and bundles.

  OSC is a flexible protocol that can be used for a wide variety of real-time tasks, such as controlling multimedia devices.

  Note that this library is deliberately minimilistic and no network transport or process logic is included.

  # Concepts, messages and bundles
  You can learn more about OSC and it's concepts and how to use this library by:
  - accessing the [README file](README.md)
  - taking the [Livebook tour](livebook/oscx_tour.livemd)
  - reading the `OSCx.Message` or `OSCx.Bundle` module documentation.

  ## Example
  To encode a basic message:
  ```
  iex> my_message = %OSCx.Message{address: "/my_synth/volume", arguments: [0.25]}
  %OSCx.Message{address: "/my_synth/volume", arguments: [0.25]}

  iex> binary_message = OSCx.encode(my_message)
  <<47, 109, 121, 95, 115, 121, 110, 116, 104, 47, 118, 111, 108, 117, 109, 101,
  0, 0, 0, 0, 44, 102, 0, 0, 62, 128, 0, 0>>
  ```
  To decode a binary OSC message:
  ```
  iex> binary_message = <<47, 109, 121, 95, 115, 121, 110, 116, 104, 47, 118, 111, 108, 117, 109, 101, 0, 0, 0, 0, 44, 102, 0, 0, 62, 128, 0, 0>>
  <<47, 109, 121, 95, 115, 121, 110, 116, 104, 47, 118, 111, 108, 117, 109, 101,
  0, 0, 0, 0, 44, 102, 0, 0, 62, 128, 0, 0>>

  iex> decoded_message = OSCx.decode(binary_message)
  %OSCx.Message{address: "/my_synth/volume", arguments: [0.25]}
  ```
  """

  @doc """
  Encodes an `%OSCx.Message{}` or `%OSCx.Bundle{}` structs as an OSC message packet.

  ## Example
  ```
  iex> %OSCx.Message{address: "/status", arguments: [1]} |> OSCx.encode()
  <<47, 115, 116, 97, 116, 117, 115, 0, 44, 105, 0, 0, 0, 0, 0, 1>>
  ```
  """
  def encode(message) when is_struct(message, OSCx.Message), do: OSCx.Message.encode(message)

  @doc """
  Decodes a binary OSC Message or Bundle.

  ## Example
  ```
  iex> binary_msg = <<47, 115, 116, 97, 116, 117, 115, 0, 44, 105, 0, 0, 0, 0, 0, 1>>
  <<47, 115, 116, 97, 116, 117, 115, 0, 44, 105, 0, 0, 0, 0, 0, 1>>

  iex> binary_msg |> OSCx.decode()
  %OSCx.Message{address: "/status", arguments: [0]}
  ```
  """
  def decode(message) when is_binary(message), do: OSCx.Message.decode(message)
end