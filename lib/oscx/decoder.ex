defmodule OSCx.Decoder do
  @moduledoc """
  Helpers to decode an OSC message into Elixir.

  This module contains helper functions that parse OSC binary data and converts them into equivalent Elixir types.

  To decode the full OSC data, these functions are chained together and are used by `OSCx.Message.decode/1` and `OSCx.Bundle.decode/1`.

  > #### Tip {: .tip}
  >
  > Note that in practice you'll will likely not need to use this module directly and instead use `OSCx.decode/1`.
  """
  alias OSCx.Decoder

  @doc section: :type
  @doc """
  Extracts the list of tags.

  Takes the binary data from the message. This assumes that the address has been removed from the start of the OSC message, and only the tag type string and arguments are remaining:

  > <OSC address> + <OSC tag type string with padding> + <OSC arguments>

  Returns a tuple with the first element containing the tags (with the leading comma removed), and the second element the remaining binary data with tag type string and it's padding removed.
  """
  def tag_list(bin_data) do
    [<<?,, tags::binary>>=tag_type_string, args_data] = :binary.split(bin_data, <<0>>)
    {tags, Decoder.de_pad(tag_type_string, args_data)}
  end

  @doc section: :type
  @doc """
  Extracts the address from the binary.

  This function assumes the OSC binary is in the following format:

  > <OSC address> + <OSC tag type string with padding> + <OSC arguments>

  It returns a tuple with the first element containing the OSC address, and the second the remaining OSC data which will be the tag type string followed by OSC arguments.
  """
  def address(bin_data) do
    [address, rest] = :binary.split(bin_data, <<0>>)
    {address, de_pad(address, rest)}
  end

  @doc section: :primary
  @doc """
  Decodes arguments from the binary.

  This function takes the following parameters:
  - List (charlist) of tag types (e.g. ?s for string, ?i for integer, etc)
  - Binary data, with the address and tag type string removed so that only argument data remains

  Returns the arguments data as a list.
  """
  def decode_arg(tag_list, arg_data, acc \\ [])
  def decode_arg([], _arg_data, acc), do: Enum.reverse(acc)
  def decode_arg([tag | rest_tags]=_tag_list, arg_data, acc) do
    IO.inspect(tag, label: "Decoding type")
    IO.inspect(arg_data, label: "Arg data")
    {decoded_data, rest_arg_data} =
      case tag do
        ?s -> Decoder.string(arg_data)
        ?i -> Decoder.integer(arg_data)
        ?f -> Decoder.float(arg_data)
        # ?b -> Decoder.boolean(arg)
        ?a -> Decoder.blob(arg_data)
        nil -> raise "Invalid OSC type tag: #{tag}"
      end

    decode_arg(rest_tags, rest_arg_data, [decoded_data | acc])
  end

  @doc section: :type
  @doc """
  Decodes a 32-bit integer from the head of the binary.

  Returns a tuple with the first element the integer value, and the second element the remainding binary data.
  """
  def integer(binary) do
    <<integer::big-size(32), rest::binary>> = binary
    {integer, rest}
  end

  @doc section: :type
  @doc """
  Decodes a 32-bit float from the head of the binary.

  Returns a tuple with the first element the float value, and the second element the remainding binary data.
  """
  def float(binary) do
    <<float::big-float-size(32), rest::binary>> = binary
    {float, rest}
  end

  @doc section: :type
  @doc """
  Extracts a string from the binary.

  This function assumes that the binary starts with a string type.

  Any additional padding added to the string is removed.

  Returns a tuple with the first element containg the string value, and the second element the remaining binary data.

  This is similar to the `OSCx.Decoder.blob/1` function.

  ## Example
  ```
  iex> bin_string = <<72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100, 33, 0, 0, 0>>
  <<72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100, 33, 0, 0, 0>>

  iex> OSCx.Decoder.string(bin_string)
  {"Hello, world!", ""}
  ```
  """
  def string(binary) do
    [string, rest] = :binary.split(binary, <<0>>)
    {string, Decoder.de_pad(string, rest)}
  end


  @doc section: :type
  @doc """
  Extracts a blob (non-string binary sequence) from the binary.

  This function assumes that the binary starts with the blob type.

  Any additional padding added to the blob is removed.

  Returns a tuple with the first element containg the blob value, and the second element the remaining binary data.

  This is similar to the `OSCx.Decoder.string/1` function.
  """
  def blob(binary) do
    <<size::big-size(32), blob::binary-size(size), rest::binary >> = binary
    {blob, Decoder.de_pad(size, rest)}
  end

  @doc section: :type
  @doc """
  Extracts a time-tag from the head of the binary.

  This function assumes that the binary starts with a time-tag.

  Returns a tuple with the first element containg the time tag as a map, and the second element the remaining binary data.

  The time tag map is in the format:
  ```
  %{seconds: seconds, fraction: fraction}
  ```
  Where:
  - `seconds` is the number of seconds since midnight on January 1, 1900
  - `fraction` is the fractional part of a second to a precision of about 200 picoseconds.
  Both of these are 32-bit integers.
  """
  def time(binary) do
    <<seconds::big-size(32), fraction::big-size(32), rest::binary>> = binary
    {%{seconds: seconds, fraction: fraction}, rest}
  end

  @doc section: :helper
  @doc """
  Removes padding prepended to remaining binary data.

  OSC messages are encoded in chunks of 4 bytes. When arbitary data, such as a string or blob is less that 4 bytes, padding using a value of `<<0>>` is added.

  This function takes the following parameters:
  - String or Blob (both are binary data of an arbitary length) OR byte size of the string or blob
  - Remaning binary data once the String or Blob has been extracted

  Returns the remaing binary data with any leading padding removed.

  ## Example
  ### String
  ```
  iex> bin_string = <<72, 101, 108, 108, 111, 0, 0, 0, 119, 111, 114, 108, 100, 33, 0, 0>>
  <<72, 101, 108, 108, 111, 0, 0, 0, 119, 111, 114, 108, 100, 33, 0, 0>>

  iex> [string, rest] = :binary.split(bin_string, <<0>>)
  ["Hello", <<0, 0, 119, 111, 114, 108, 100, 33, 0, 0>>]

  # Leading padding will be removed, based on the previous strings size
  iex> OSCx.Decoder.de_pad(string, rest)
  <<119, 111, 114, 108, 100, 33, 0, 0>>
  ```
  ### Byte size
  ```
  iex> bin_string = <<72, 101, 108, 108, 111, 0, 0, 0, 119, 111, 114, 108, 100, 33, 0, 0>>
  <<72, 101, 108, 108, 111, 0, 0, 0, 119, 111, 114, 108, 100, 33, 0, 0>>

  iex> [string, rest] = :binary.split(bin_string, <<0>>)
  ["Hello", <<0, 0, 119, 111, 114, 108, 100, 33, 0, 0>>]

  # Set byte size to 5 ("Hello" has byte size of 5). Any leading padding will be removed based on this size.
  iex> OSCx.Decoder.de_pad(5, rest)
  <<119, 111, 114, 108, 100, 33, 0, 0>>
  ```
  """
  def de_pad(string_or_blob_or_size, bin_data) when is_binary(string_or_blob_or_size) do
    de_pad(byte_size(string_or_blob_or_size), bin_data)
  end
  def de_pad(size, bin_data) when is_number(size) do
    depad_amt =
      case rem(size, 4) do
        0 -> 3
        1 -> 2
        2 -> 1
        3 -> 0
      end

    binary_part(bin_data, depad_amt, byte_size(bin_data)-depad_amt)
  end

  @doc section: :helper
  @doc """
  Generates a list showing each 'row' of the encoded OSC message.

  This maybe useful in debugging OSC binary messages.

  The OSCx.Decoder.inspect() shows:
  - the character code of each byte
  - its printable utf8 value
  - underscore (_) is used to denote either a 0 value or padding
  - (D) is a non-printable data value

  ## Example
  ```
  iex> encoded_msg =
    %OSCx.Message{address: "/target/address", arguments: [1, 2.0, "string data"]}
    |> OSCx.encode()

  # Inspect the message to see how it is encoded
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
  """
  def inspect(binary_message) do
    binary_message
    |> to_charlist()
    |> Enum.map(fn byte ->
      cond do
        String.printable?(<<byte::utf8>>) -> "#{byte} \'#{<<byte::utf8>>}\'"
        byte == 0 -> "#{byte} (_)"
        true -> "#{byte} (D)"
      end
    end)
    |> Enum.chunk_every(4)
    |> Enum.with_index(fn (d, i) ->
      { i, d }
    end)
  end
end
