defmodule OSCx.Bundle do
  @moduledoc """
  A module and struct for manipulating and representing OSC bundles.

  The struct has two keys:
  - `time:` a map representing an OSC time tag, in the format `%{time: _, fraction: _}`
  - `elements:` an Elixir list of Messages or Bundles.

  The two main functions are:
  - `encode/1` which takes an `%OSCx.Bundle{}` struct and encodes it to the OSC bundle format
  - `decode/1` which takes an OSC bundle recieved (e.g. via UDP) and decodes it into an `%OSCx.Bundle{}` struct.

  ## About OSC bundles
  Bundles are a way of grouping OSC messages and even other OSC bundles together, so they can be received by the OSC server simultaneously.

  ### Structure of an OSC bundle
  A bundle is made up of three parts:
  - Bundle identifer: which is the the string “#bundle”.
  - Time: a time tag which is a 64-bit time identifier. The first 32 bits specify the number of seconds since midnight on January 1, 1900, and the last 32 bits specify fractional parts of a second to a precision of about 200 picoseconds. This representation is used by Internet NTP timestamps.
  - Elements: the payload of the bundle, which can be any number of messages or bundles. Each of these are preceded by a 4-byte integer byte count.

  ![OSC bundle diagram](assets/osc-bundle.png)

  Calling `OSCx.encode/1` or `OSCx.Bundle.encode/1` on an `%OSCx.Bundle{}` will create the OSC binary version matching the above.

  ## Creating a bundle
  To create a bundle, you only need to specify the time tag and add the elements (which are `%OSCx.Messages{}` or other `%OSCx.Bundle{}` structs) to be included within the bundle:
  ```
  iex> my_bundle =
    %OSCx.Bundle{
      time: %{seconds: 1, fraction: 0},
      elements: [%OSCx.Message{address: "/", arguments: []}]
    }
  ```
  Or you can use `OSCx.Bundle.new/1` to build the struct.

  ## Sending the bundle
  The bundle is sent just like an `OSCx.Message`, for example, using UDP:
  ```
  # IP or host and port number for the UDP connection
  ip_address = '127.0.0.1' # This could be changed to named address, like 'localhost'
  port_num = 8000 # In this example, this is the default port used by [Protokol](https://hexler.net/protokol)

  # Open a port
  {:ok, port} = :gen_udp.open(0, [:binary, {:active, true}])

  # Encode the message
  my_bundle =
    %OSCx.Bundle{
      time: %{seconds: 1, fraction: 0},
      elements: [
        %OSCx.Message{address: "/msg/one", arguments: [1]},
        %OSCx.Message{address: "/msg/two", arguments: [2]},
        %OSCx.Message{address: "/msg/three", arguments: [3]}
        ]
    } |> OSCx.encode()

  # Send message
  :gen_udp.send(port, ip_address, port_num, my_bundle)
  ```
  """

  defstruct time: %{seconds: 0, fraction: 0}, elements: []
  alias OSCx.Encoder

  @doc """
  Convenience for creating a new `%OSCx.Bundle{}` struct.

  Optionally takes a keyword list with the following keys:
  - `time:` which can be used to set the OSC time tag map, e.g. `%{seconds: 1, fraction: 1}`
  - `elements:` which is a list of elements to include in the bundle. Elements can include zero, 1 or more `%OSCx.Message{}` or `%OSCx.Bundle{}` structs.

  ## Example
  ```
  Bundle.new(
      time: %{seconds: 1, fraction: 1},
      elements: [
        Message.new(address: "/synth/play", arguments: [440.0]),
        Message.new(address: "/synth/stop", arguments: [440.0]),
      ]
    )
  ```
  """
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end

  @doc """
  Encodes an `%OSCx.Bundle{}` struct to an OSC Bundle binary.

  Takes a `%OSCx.Bundle{}` struct as it's first parameter.

  In practice, just use `OSCx.encode/1` instead as it will encode Bundle or Message types.

  ## Example
  ```
  iex> my_bundle =
    Bundle.new(
      time: %{seconds: 1, fraction: 1},
      elements: [
        Message.new(address: "/synth/play", arguments: [440.0]),
        Message.new(address: "/synth/stop", arguments: [440.0])
      ]
    )
  %OSCx.Bundle{
    time: %{seconds: 1, fraction: 1},
    elements: [
      %OSCx.Message{address: "/synth/play", arguments: [440.0]},
      %OSCx.Message{address: "/synth/stop", arguments: [440.0]}
    ]
  }

  iex> my_bundle |> OSCx.Bundle.encode()
  <<35, 98, 117, 110, 100, 108, 101, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 20, 47,
  115, 121, 110, 116, 104, 47, 112, 108, 97, 121, 0, 44, 102, 0, 0, 67, 220, 0,
  0, 0, 0, 0, 20, 47, 115, 121, 110, 116, 104, ...>>
  ```
  """
  def encode(bundle) do
    [
      # 1. OSC-string
      "#bundle" <> <<0>>,

      # 2. OSC-timetag
      Encoder.time(bundle.time) |> elem(1),

      # 3. Element size <> Element (bundle or message)
      encode_elements(bundle.elements)
    ]
    |> :binary.list_to_bin()
  end

  defp encode_elements(elements) when is_list(elements) do
    for element <- elements do
      element
      |> OSCx.encode()
      |> OSCx.Encoder.prefix_size()
    end
  end
  defp encode_elements(elements), do: encode_elements([elements])

  @doc """
  Decodes an OSC binary bundle into an `%OSCx.Bundle{}` struct.

  ## Example
  ```
  iex> alias OSCx.{Bundle, Message}
  [OSCx.Bundle, OSCx.Message]

  iex> binary_osc_bundle =
    Bundle.new(
      time: %{seconds: 1, fraction: 1},
      elements: [
        Message.new(address: "/synth/play", arguments: [440.0]),
        Message.new(address: "/synth/stop", arguments: [440.0]),
        Bundle.new(
          time: %{seconds: 1, fraction: 2},
          elements: [ Message.new(address: "/inner_bundle/message", arguments: ["yes, they can be nested!"]) ]
        )
      ]
    ) |> OSCx.encode()
  <<35, 98, 117, 110, 100, 108, 101, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 20, 47,
  115, 121, 110, 116, 104, 47, 112, 108, 97, 121, 0, 44, 102, 0, 0, 67, 220, 0,
  0, 0, 0, 0, 20, 47, 115, 121, 110, 116, 104, ...>>

  # Decode the binary OSC message above, back into a struct
  iex> binary_osc_bundle |> OSCx.decode()
  %OSCx.Bundle{
    time: %{seconds: 1, fraction: 1},
    elements: [
      %OSCx.Message{address: "/synth/play", arguments: [440.0]},
      %OSCx.Message{address: "/synth/stop", arguments: [440.0]},
      %OSCx.Bundle{
        time: %{seconds: 1, fraction: 2},
        elements: [
          %OSCx.Message{
            address: "/inner_bundle/message",
            arguments: ["yes, they can be nested!"]
          }
        ]
      }
    ]
  }
  ```
  """
  def decode(binary_bundle) do
    <<35, 98, 117, 110, 100, 108, 101, 0, seconds::big-size(32), fraction::big-size(32), elements_bin::binary>>=binary_bundle

    %__MODULE__{time: %{seconds: seconds, fraction: fraction}, elements: decode_elements(elements_bin)}
  end

  defp decode_elements(binary, acc \\ [])
  defp decode_elements("", acc), do: acc |> Enum.reverse()
  defp decode_elements(binary, acc) do
    <<byte_size::big-size(32), element::binary-size(byte_size), rest_bin::binary>> = binary
    decode_elements(rest_bin, [OSCx.decode(element)] ++ acc)
  end

end
