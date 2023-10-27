defmodule OSCx.Decoder do
  @moduledoc """
  Helpers to decode an OSC message into Elixir.

  This module contains helper functions that parse OSC binary data and converts them into equivalent Elixir types.

  To decode the full OSC data, these functions are chained together and are used by `OSCx.Message.decode/1` and `OSCx.Bundle.decode/1`.

  > #### Tip {: .tip}
  >
  > Note that in practice you'll will likely not need to use this module directly and instead use `OSCx.decode/1`.

  ## Automatically decoded types
  ### Types with arguments
  The following types can be automatically decoded:

  | Type tag | Unicode number | Type            | OSC spec version |
  | -------- | -------------- | --------------- | ---------------- |
  | i        | 105            | 32 bit integer  | 1.0+ required    |
  | f        | 102            | 32 bit float    | 1.0+ required    |
  | s        | 115            | String          | 1.0+ required    |
  | b        | 98             | Blob            | 1.0+ required    |
  | h        | 104            | 64-bit big-endian two’s complement integer | 1.0 non-standard |
  | m        | 109            | 4 byte MIDI message | 1.0 non-standard |
  | t        | 116            | OSC time tag    | 1.1+ required    |
  | S        | 83             | Symbol          | 1.0 non-standard    |
  | [ and ]  | 91 and 93      | List            | 1.0 non-standard    |

  ### Symbols, Atoms and Strings
  By default, Symbols are converted to Elixir atoms. This behaviour can be changed, see `OSCx.Decoder.set_symbol_to_atom/1`.

  ### Special string tag types
  The following string type tags are also automatically decoded via the `tag/1` function:

  | Type tag | Unicode number | Type            | OSC spec version |
  | -------- | -------------- | --------------- | ---------------- |
  | T        | 84             | True (tag only, no arguments) | 1.1+ required |
  | F        | 80             | False (tag only, no arguments) | 1.1+ required |
  | N        | 78             | Null (tag only, no arguments) | 1.1+ required |
  | I        | 73             | Impulse (tag only, no arguments) | 1.1+ required |

  ## More information
  To learn more about how this library decodes and encodes data, see: [Arguments and types](arguments_and_types.md).
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

  Currently this automatically decodes the following argument types:

  | Type tag | Unicode number | Type            | OSC spec version |
  | -------- | -------------- | --------------- | ---------------- |
  | i        | 105            | 32 bit integer  | 1.0+ required    |
  | f        | 102            | 32 bit float    | 1.0+ required    |
  | s        | 115            | String          | 1.0+ required    |
  | b        | 98             | Blob            | 1.0+ required    |
  | h        | 104            | 64-bit big-endian two’s complement integer | 1.0 non-standard |
  | m        | 109            | 4 byte MIDI message | 1.0 non-standard |
  | t        | 116            | OSC time tag    | 1.1+ required    |
  | S        | 83             | Symbol          | 1.0 non-standard    |
  | [ and ]  | 91 and 93      | List            | 1.0 non-standard    |

  This function takes the following parameters:
  - List (charlist) of tag types (e.g. ?s for string, ?i for integer, etc)
  - Binary data, with the address and tag type string removed so that only argument data remains

  Returns a tuple with the first element containing the decoded data, and the second element any remaining data. The second element will be an empty binary if all data was successfully decoded to the end.
  """
  def decode_arg(tag_list, arg_data, acc \\ [])
  def decode_arg([], remaining_arg_data, acc), do: { Enum.reverse(acc) |> Enum.filter(&(&1 != :other)), remaining_arg_data }
  def decode_arg([tag | rest_tags]=_tag_list, arg_data, acc) do
    {decoded_data, rest_arg_data, rest_tags} =
      case tag do
        ?i -> Decoder.integer(arg_data, rest_tags)
        ?f -> Decoder.float(arg_data, rest_tags)
        ?s -> Decoder.string(arg_data, rest_tags)
        ?b -> Decoder.blob(arg_data, rest_tags)
        ?h -> Decoder.integer_64bit(arg_data, rest_tags)
        ?m -> Decoder.midi(arg_data, rest_tags)
        ?t -> Decoder.time(arg_data, rest_tags)
        ?S -> Decoder.symbol(arg_data, rest_tags)
        ?[ -> Decoder.list(arg_data, rest_tags)
        _other -> {:other, arg_data, rest_tags}
      end

    decode_arg(rest_tags, rest_arg_data, [decoded_data | acc])
  end

  @doc section: :type
  @doc """
  Decodes a 32-bit integer from the head of the binary.

  Returns a tuple with the:
  - first element: the integer value
  - second element: the remaining binary data
  - third element: the rest of the type tags to be processed.
  """
  def integer(binary, rest_tags) do
    <<integer::big-size(32), rest::binary>> = binary
    {integer, rest, rest_tags}
  end

  @doc section: :type
  @doc """
  Decodes a 64-bit integer from the head of the binary.

  Returns a tuple with the:
  - first element: the integer value
  - second element: the remaining binary data
  - third element: the rest of the type tags to be processed.
  """
  def integer_64bit(binary, rest_tags) do
    <<integer::big-size(64), rest::binary>>=binary
    {integer, rest, rest_tags}
  end

  @doc section: :type
  @doc """
  Decodes a 32-bit float from the head of the binary.

  Returns a tuple with the first element the float value, and the second element the remaining binary data.

  Returns a tuple with the:
  - first element: the float value
  - second element: the remaining binary data
  - third element: the rest of the type tags to be processed.
  """
  def float(binary, rest_tags) do
    <<float::big-float-size(32), rest::binary>> = binary
    {float, rest, rest_tags}
  end

  @doc section: :type
  @doc """
  Extracts a string from the binary.

  This function assumes that the binary starts with a string type.

  Any additional padding added to the string is removed.

  Returns a tuple with the:
  - first element: the string value
  - second element: the remaining binary data
  - third element: the rest of the type tags to be processed.

  This is similar to the `OSCx.Decoder.blob/2` function.

  ## Example
  ```
  iex> bin_string = <<72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100, 33, 0, 0, 0>>
  <<72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100, 33, 0, 0, 0>>

  iex> OSCx.Decoder.string(bin_string)
  {"Hello, world!", ""}
  ```
  """
  def string(binary, rest_tags) do
    [string, rest] = :binary.split(binary, <<0>>)
    {string, Decoder.de_pad(string, rest), rest_tags}
  end

  @doc section: :type
  @doc """
  Extracts a symbols from the binary.

  In the OSC 1.0 Specification, this is considered an alternate OSC-string representation, used for example in systems that differentiate “symbols” from “strings”.

  ##
  This function assumes that the binary starts with a symbol type.

  Any additional padding added to the symbol is removed.

  Returns a tuple with the:
  - first element: the symbol as an atom (or string if default behaviour is changed, see below)
  - second element: the remaining binary data
  - third element: the rest of the type tags to be processed.

  This is similar to the `OSCx.Decoder.string/2` function.

  ## Symbols become `:atoms` by default
  In this library, Elixir's atom type is considered an OSC Symbol type.

  Uncontrolled creation of atoms is not considered good pratice on the BEAM. If there are potentially a lot of Symbols being decoded, consider decoding to a String instead.

  This default behaviour can be changed by calling `OSCx.Decoder.set_symbol_to_atom(false)` or setting the application environment `Application.get_env(:OSCx, :symbol_to_atom, false)`.

  For more information, see `OSCx.Decoder.set_symbol_to_atom/1`.
  """
  def symbol(binary, rest_tags) do
    [symbol, rest] = :binary.split(binary, <<0>>)
    de_padded_bin = Decoder.de_pad(symbol, rest)
    # Convert Symbol type to Elixir atom, unless otherwise specified in the application environment
    symbol = if Application.get_env(:OSCx, :symbol_to_atom, true), do: String.to_atom(symbol), else: symbol
    {symbol, de_padded_bin, rest_tags}
  end


  @doc section: :type
  @doc """
  Extracts a blob (non-string binary sequence) from the binary.

  This function assumes that the binary starts with the blob type.

  Any additional padding added to the blob is removed.

  Returns a tuple with the:
  - first element: the blob value
  - second element: the remaining binary data
  - third element: the rest of the type tags to be processed.

  This is similar to the `OSCx.Decoder.string/2` function.
  """
  def blob(binary, rest_tags) do
    <<size::big-size(32), blob::binary-size(size), rest::binary >> = binary
    {blob, Decoder.de_pad(size, rest), rest_tags}
  end

  @doc section: :type
  @doc """
  Extracts a time-tag from the head of the binary.

  This function assumes that the binary starts with a time-tag.

  Returns a tuple with the:
  - first element: the map value for a time tag (see below)
  - second element: the remaining binary data
  - third element: the rest of the type tags to be processed.

  The time tag map is in the format:
  ```
  %{seconds: seconds, fraction: fraction}
  ```
  Where:
  - `seconds` is the number of seconds since midnight on January 1, 1900
  - `fraction` is the fractional part of a second to a precision of about 200 picoseconds.
  Both of these are 32-bit integers.
  """
  def time(binary, rest_tags) do
    <<seconds::big-size(32), fraction::big-size(32), rest::binary>> = binary
    {%{seconds: seconds, fraction: fraction}, rest, rest_tags}
  end

  @doc section: :type
  @doc """
  Extracts a MIDI message from the head of the binary.

  This function assumes that the binary starts with a MIDI message.

  Returns a tuple with the:
  - first element: a map with a 4-byte MIDI value, in the format: `%{midi: value}`
  - second element: the remaining binary data
  - third element: the rest of the type tags to be processed.
  """
  def midi(binary, rest_tags) do
    <<value::binary-size(4), rest::binary>> = binary
    {%{midi: value}, rest, rest_tags}
  end

  @doc section: :type
  @doc """
  Parses a list (or array as it is called in OSC).

  Returns a tuple with the:
  - first element: a list containing the decoded array data
  - second element: the remaining binary data
  - third element: the rest of the type tags to be processed.
  """
  def list(binary, type_tag_string) do
    array_tags = Enum.take_while(type_tag_string, fn char -> char != ?] end)
    rem_tag_type_string = type_tag_string -- (array_tags ++ ~c"]")
    {decoded_array_data, rest_arg_data} = decode_arg(array_tags, binary)
    {decoded_array_data, rest_arg_data, rem_tag_type_string}
  end

  @doc section: :helper
  @doc """
  Parses a tag string for special tag types.

  Takes a type tag string as the first parameter, with or without the leading comma.

  Parses a tag string to check if any of the following special types are present:

  | OSC string tag type | OSC character | Elixir type |
  | True | T | true |
  | False | F | false |
  | Null | N | nil |
  | Impulse | I | :impulse |

  Return type is a list of zero or more of the above.

  ## Example
  ```
  # Single 'true' type present
  iex> Decoder.tag(",T")
  [true]

  # Single 'false' type present
  iex> Decoder.tag(",F")
  [false]

  # Single 'null' type present, will return nil in Elixir
  iex> Decoder.tag(",N")
  [nil]

  # Multiple special types given.
  iex> Decoder.tag(",FTNI")
  [false, true, nil, :impulse]

   # No special types present, other tags ignored. Empty list is returned.
  iex> Decoder.tag(",ifs")
  []
  ```
  """
  def tag(tag_type_string) do
    String.to_charlist(tag_type_string)
    |> Enum.map(fn char ->
      case char do
        ?, -> :ignore
        ?T -> true
        ?F -> false
        ?N -> nil
        ?I -> :impulse
        _ -> :other
      end
    end)
    |> Enum.filter(fn type -> type not in [:other, :ignore] end)
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

  @doc section: :helper
  @doc """
  Sets the default behaviour when decoding of OSC Symbol types.

  Takes as its first parameter a boolean representing the following behaviour:
  - true: OSC Symbols are converted to Elixir atoms. This is the default behaviour.
  - false: OSC Symbols are converted to Elixir strings.

  This function changes the `:OSCx, :symbol_to_atom` application evironment, e.g.: `Application.get_env(:OSCx, :symbol_to_atom, false)`.

  ## Why this option?
  Uncontrolled dynamic creation of atoms on the BEAM may not be considered good practice.
  Atoms are not garbage collected by the Erlang Virtual Machine, so they live in memory during a software's entire execution lifetime.
  Although there is a high-limit on the number of atoms that can be created on the BEAM, for situations where there may be a large variety of atoms, converting to Elixir's string type may be preferrable.
  For more information on this see [Code-related anti-patterns](https://hexdocs.pm/elixir/main/code-anti-patterns.html).
  """
  def set_symbol_to_atom(true_or_false \\ true) do
      Application.put_env(:OSCx, :symbol_to_atom, true_or_false)
  end
end
