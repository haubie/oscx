defmodule OSCx.Message do
  @moduledoc """
  A module and struct for manipulating and representing OSC messages.

  The struct has two keys:
  - `address:` representing the OSC address. Defaults to the root address of `"/"`
  - `arguments:` an Elixir list of arguments. Defults to an empty list `[]`.

  The two main functions are:
  - `encode/1` which takes an `%OSCx.Message{}` struct and encodes it to the OSC message format
  - `decode/1` which takes an OSC message recieved (e.g. via UDP) and decodes it into an `%OSCx.Message{}` struct.

  ## Structure of OSC messages
  OSC messages are made up of three parts:
  1. **Address** which represents the function you want to control starting with a forward slash e.g. `"/status"`
  2. **Tag type string**: which lists the data types in the data payload, in the order they occur. Note that some older implementations of OSC may omit the OSC Type Tag string.
  3. **Arguments**: the data payload which could be any of the OSC types.

  ![OSC message diagram](assets/osc-message.png)

  ## Creating a message
  When you create a message, you only need to specify the address and the arguments like this:
  ```
  iex> my_msg = %OSCx.Message{address: "/target/address", arguments: [1, 2.0, "string data"]}
  ```
  The tag type string is automatically generated when the message is encoded:
  ```
  # Encode the message above
  iex> encoded_msg = my_msg |> OSCx.encode()

  # Inspect the message to see how it is encoded
  # The OSCx.Decoder.inspect() shows:
  # - the character code of each byte
  # - its printable utf8 value
  # - underscore (_) is used to denote either a 0 value or padding
  # - (D) is a non-printable data value
  iex> encoded_msg |> OSCx.Decoder.inspect()
  [
    {0, ["47 '/'", "116 't'", "97 'a'", "114 'r'"]},
    {1, ["103 'g'", "101 'e'", "116 't'", "47 '/'"]},
    {2, ["97 'a'", "100 'd'", "100 'd'", "114 'r'"]},
    {3, ["101 'e'", "115 's'", "115 's'", "0 (_)"]},
    {4, ["44 ','", "105 'i'", "102 'f'", "115 's'"]},
    {5, ["0 (_)", "0 (_)", "0 (_)", "0 (_)"]},
    {6, ["0 (_)", "0 (_)", "0 (_)", "1 (D)"]},
    {7, ["64 '@'", "0 (_)", "0 (_)", "0 (_)"]},
    {8, ["115 's'", "116 't'", "114 'r'", "105 'i'"]},
    {9, ["110 'n'", "103 'g'", "32 ' '", "100 'd'"]},
    {10, ["97 'a'", "116 't'", "97 'a'", "0 (_)"]}
  ]
  ```
  You can see on row number 4, the automatically encoded type string of `,ifs` which means integer, float and string which was created for the OSC message arguments of `[1, 2.0, "string data"]`.

  ## Transmitting and receiving messages
  OSC messages are independent from any specific transport mechanism, and can be transmitted and receivied over a variety of networks, including Ethernet, Wi-Fi, and the Internet.

  ### Using UDP
  Even though OSC messages are transport mechanism agnostic, they are commonly sent and received using UDP sockets.

  The Erlang `:gen_utp` module can be used for this purpose. It provides the functions necessary for communicating with sockets using the UDP protocol.

  ## Example
  ```
  # IP or host and port number for the UDP connection
  ip_address = '127.0.0.1' # This could be changed to named address, like 'localhost'
  port_num = 57110 # In this example, this is the default port used by SuperCollider

  # Open a port
  {:ok, port} = :gen_udp.open(0, [:binary, {:active, true}])

  # Encode the message
  osc_message = %OSCx.Message{address: "/version", arguments: []} |> OSCx.encode()

  # Send message
  :gen_udp.send(port, ip_address, port_num, osc_message)
  ```

  ## More information
  See the OSC specification website at: https://opensoundcontrol.stanford.edu/index.html
  """
  defstruct address: "/", arguments: []

  alias OSCx.Message
  alias OSCx.Encoder
  alias OSCx.Decoder

  def new(opts \\ [])
  def new(opts) when is_map_key(opts, :tags)  do
    IO.puts "TAG GIVEN"
  end
  def new(opts) do
    struct(__MODULE__, opts)
  end

  @doc """
  Encodes an `%OSCx.Message{}` struct to an OSC binary message.

  This function takes a populated `%OSCx.Message{}` struct as its first and only parameter.

  It returns a binary message in the format:

  > **<OSC address>** followed by an **<OSC type tag string>** followed by **<zero or more OSC arguments>**.

  In practice, use `OSCx.encode/1` instead which can accept messages or bundles.

  ## Example
  ```
  iex> %OSCx.Message{address: "/status", arguments: []} |> OSCx.Message.encode()
  <<47, 115, 116, 97, 116, 117, 115, 0, 44, 0, 0, 0>>
  ```
  """
  def encode(message) when is_struct(message, OSCx.Message) do
    encoded_arguments = Enum.map(message.arguments, &Encoder.encode_arg(&1))
    # Arbitary length data like strings in the address and tag_type_string may need padding
    address = Encoder.pad(message.address) |> List.to_string()
    tag_type_string = "," <> Encoder.type_tag_string(encoded_arguments) |> Encoder.pad() |> Enum.join(<<>>)
    arguments = Encoder.encoded_value(encoded_arguments) |> List.flatten() |> Enum.join(<<>>)

    # Encoded message is: <OSC Address Pattern> followed by an <OSC Type Tag String> followed by <zero or more OSC Arguments>.
    address <> tag_type_string <> arguments
  end

  @spec decode(any()) :: Message
  @doc """
  Decodes a binary OSC message.

  ## Example
  ```
  # Binary OSC message
  iex> bin_msg = <<47, 115, 116, 97, 116, 117, 115, 0, 44, 0, 0, 0>>
  <<47, 115, 116, 97, 116, 117, 115, 0, 44, 0, 0, 0>>

  iex> decoded_msg = OSCx.Message.decode(bin_msg)
  %OSCx.Message{address: "/status", arguments: []}
  ```

  In practice, use `OSCx.decode/1` instead which can accept messages or bundles.
  """
  def decode(message) do
    # Split the message into the address, tag_type_string and arguments.
    {address, rest} = Decoder.address(message)
    {tag_type_string, args_data} = Decoder.tag_list(rest)
    # Decode the arguments.
    args = Decoder.decode_arg(to_charlist(tag_type_string), args_data)

    %Message{address: address, arguments: args}
  end

end
