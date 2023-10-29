defmodule OSCx.Encoder do
  @moduledoc """
  Helpers to encode Elixir types into OSC data types.

  This module contains helper functions used to encode supported Elixir types (see below) into OSC binary data.

  To encode the full OSC data, these functions are chained together and are used by `OSCx.Message.encode/1` and `OSCx.Bundle.encode/1`.

  > #### Tip {: .tip}
  >
  > Note that in practice you'll will likely not need to use this module directly and instead use `OSCx.encode/1`.

  At it's core, OSC has the following data types:

  | Type        | Description |
  | ----------- | ----------- |
  | **Integer** | a 32-bit signed integer and also a 64-bit integer type) |
  | **Float**   | a 32-bit IEEE 754 floating-point number and also a 64-bit double type |
  | **String**  | a sequence of printable ASCII characters (there are also Symbols and Char types)|
  | **Blob**    | a sequence of arbitrary binary data, with its size prepended |
  | **Timetag** | a 64-bit fixed-point number that represents a time in seconds since midnight on January 1, 1900. The first 32 bits of the timetag represent the number of seconds, and the last 32 bits represent fractional parts of a second to a precision of about 200 picoseconds. |

  The above are considered 'required' types by the OSC spec, however, OSC can be extended to support additional or optional types.

  The main function in this module is `encode_arg/1`, which takes one of the recognised Elixir data types, and returns it as an OSC type.

  ## Tag-specific types
  Additionally the [OSC 1.1 Specification](https://opensoundcontrol.stanford.edu/spec-1_1.html) includes some types which carry no data arguments, but can be encoded directly into the tag type string. These are True, False, Null and Impluse.

  See the [Tag specific](#tag-specific) functions below.

  ## 4-byte boundaries
  OSC data is aligned on 4-byte boundaries. 32-bit types like Integers and Floats are 4-bytes, but Strings and Blobs can be of an arbintary length. For this reason they may be padded with extra null characters (`<<0>>>` is used in Elixir) to make the total length a multiple of 4 bytes.

  ## Values returned
  [Most functions](#type-functions) in this module return a tuple in the form `{type, value}`. These are defined as follows:
  - **type**: first element is an OSC type tag, which is a unicode charater representing the type
  - **value**: second element is the encoded OSC value.

  For example, `{105, <<0, 0, 0, 128>>}` is returned for encoding a the integer `128`. See the example below.

  ## Type tags
  OSC type tags are unicode characters which represent each type. This library currently implements the following types:

  | Type tag | Unicode number | Type            | OSC spec version |
  | -------- | -------------- | --------------- | ---------------- |
  | i        | 105            | 32 bit integer  | 1.0+ required    |
  | f        | 102            | 32 bit float    | 1.0+ required    |
  | s        | 115            | String          | 1.0+ required    |
  | b        | 98             | Blob            | 1.0+ required    |
  | h        | 104            | 64-bit big-endian two’s complement integer | 1.0 non-standard |
  | d        | 100            | 64 bit (“double”) IEEE 754 floating point number | 1.0 non-standard |
  | c        | 99             | An ascii character, sent as 32 bits | 1.0 non-standard |
  | m        | 109            | 4 byte MIDI message | 1.0 non-standard |
  | t        | 116            | OSC time tag    | 1.1+ required    |
  | r        | 144            | 32 bit RGBA color | 1.0 non-standard |
  | [ and ]  | 91 and 93      | List            | 1.0 non-standard    |
  | T        | 84             | True (tag only, no arguments) | 1.1+ required |
  | F        | 80             | False (tag only, no arguments) | 1.1+ required |
  | N        | 78             | Null (tag only, no arguments) | 1.1+ required |
  | I        | 73             | Impulse (tag only, no arguments) | 1.1+ required |

  These type tags are used to build a type tag string, which is part of the OSC message.

  ## Example
  ```
  iex> alias OSCx.Encoder

  iex> my_integer = 128
  iex> Encoder.integer(my_integer)
  # Returns the type 105 (integer), and the encoded value:
  {105, <<0, 0, 0, 128>>}

  iex> very_big_integer = 9_223_372_036_854_775_700
  iex> Encoder.integer(very_big_integer)
  # Returns the type 104 (64-bit big-endian two’s complement integer), with the encoded value
  {104, <<127, 255, 255, 255, 255, 255, 255, 148>>}

  iex> my_string = "hello world"
  iex> Encoder.string(my_string)
  # Returns the type 115 (string), and a list containing the string with any required padding:
  {115, <<104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100, 0>>}
  ```

  ## More information
  To learn more about how this library encodes and decodes data, see: [Arguments and types](arguments_and_types.md).
  """

  ## ----------------
  ## GUARDS
  ## ----------------

  @doc section: :helper
  @doc """
  Guard to test if a time map has been provided.
  A time map is in the following format: `%{seconds: seconds, fraction: fraction}`.
  """
  defguard is_time_map(value) when is_map(value) and is_map_key(value, :seconds) and is_map_key(value, :fraction)

  @doc section: :helper
  @doc """
  Guard to test if a MIDI map has been provided.
  A MIDI map is in the following format: `%{midi: value}`.
  The value is a 4-byte binary.
  """
  defguard is_midi_map(value) when is_map(value) and is_map_key(value, :midi)

  @doc section: :helper
  @doc """
  Guard to test if a map for chars has been provided.
  """
  defguard is_char_map(value) when is_map(value) and is_map_key(value, :char)


  @doc section: :helper
  @doc """
  Guard to test if a map for chars has been provided.
  """
  defguard is_rgba_map(value) when is_map(value) and is_map_key(value, :rgba)

  ## ----------------
  ## PRIMARY FUNCTION
  ## ----------------

  @doc section: :primary
  @doc """
  Encodes an argument into its OSC type and value.

  ## Elixir to OSC types
  You can call this function with the following Elixir types:

  | Elixir type | OSC type tag | Unicode number | OSC type        |
  | ----------- | ------------ | -------------- | --------------- |
  | Integer     | i            | 105            | 32 bit integer  |
  | Float       | f            | 102            | 32 bit float    |
  | String      | s            | 115            | String          |
  | Atom        | s            | 115            | String          |
  | Bitstring   | b            | 98             | Blob            |
  | Integer (64 bit) | h       | 104            | 64-bit big-endian two’s complement integer |
  | Float (64 bit) | d         | 104            | 64-bit big-endian two’s complement integer |
  | Time map    | t            | 116            | OSC time tag    |
  | MIDI map    | m            | 109            | 4-byte MIDI message |
  | Char map    | c            | 99             | 4-byte ASCII character |

  Note the:
  - time map is in the format `%{seconds: seconds, fraction: fraction}` where seconds and fraction are 32-bit numbers.
  - MIDI map is in the format `%{midi: value}` where the value is a 4 byte MIDI message
  - Char map is in the format `%{char: value}` where value is a single character string (e.g. `"A"`), a single char (e.g. `'A'` or `~c"A"`) or an integer of an ASCII char (e.g. `65`).

  ## Return format
  The function will return a tuple with the first element containing the OSC type tag, and the second element the OSC encoded value such as `{105, <<0, 0, 0, 1>>}`.

  If an elixir List is given, each argument in the list will be encoded and a list is returned, for example:
  ```
  iex> Encoder.encode_arg([1,2,3])
  [{105, <<0, 0, 0, 1>>}, {105, <<0, 0, 0, 2>>}, {105, <<0, 0, 0, 3>>}]
  ```

  An unrecognised Elixir type will return an error tuple in the following format:
  ```
  {:error, "Unknown type"}
  ```

  ## Examples
  ```
  alias OSCx.Encoder

  # Encode an integer of value 1
  iex> Encoder.encode_arg(1)
  {105, <<0, 0, 0, 1>>}

  # Encode a float of 2.1
  iex> Encoder.encode_arg(2.1)
  {102, <<64, 6, 102, 102>>}

  # Encode a string of "hello world" (this will also add padding do the end)
  # Bit
  iex> Encoder.encode_arg("hello world")
  {115, <<104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100, 0>>}

  # Encode a 64-bit integer
  iex> Encoder.encode_arg(9_223_372_036_854_775_700)
  {104, <<127, 255, 255, 255, 255, 255, 255, 148>>}
  ```
  """
  def encode_arg(value) when (value==true), do: {?T, nil}
  def encode_arg(value) when (value==false), do: {?F, nil}
  def encode_arg(value) when (value in [nil, :null]), do: {?N, nil}
  def encode_arg(value) when (value==:impulse), do: {?I, nil}

  def encode_arg(value) when is_integer(value), do: integer(value)
  def encode_arg(value) when is_float(value), do: float(value)
  def encode_arg(value) when is_atom(value), do: symbol(value)
  def encode_arg(value) when is_bitstring(value), do: String.printable?(value) && string(value) || blob(value)
  def encode_arg(value) when is_time_map(value), do: time(value)
  def encode_arg(value) when is_midi_map(value), do: midi(value)
  def encode_arg(value) when is_char_map(value), do: char(value)
  def encode_arg(value) when is_rgba_map(value), do: rgba(value)
  def encode_arg(value) when is_list(value), do: list(value)
  def encode_arg(_value), do: {:error, "Unknown type"}


  ## --------------
  ## TYPE ENCODING
  ## --------------

  @doc section: :tag
  @doc """
  Encodes a list.

  Returns a tuple with the first element containing the OSC array type tags, and the second element containing the binary encoded array data.
  """
  def list(value) do
    {sub_types, sub_values} = Enum.map(value, &encode_arg(&1)) |> Enum.unzip()
    {[~c"[", sub_types, ~c"]"], Enum.join(sub_values, <<>>)}
  end

  @doc section: :type
  @doc """
  Encodes a 4-byte MIDI message.

  Takes as it's first parmeter a map with the key-value pair of: `%{midi: value}`.

  ## Format of the value
  The OSC defines the 4 byte MIDI messages as bytes from MSB to LSB are: port id, status byte, data1, data2.

  If only a 3 byte message is provided (e.g. a status byte followed by two data bytes), a port id of <<0>> is prepended to make 4 bytes.

  The MIDI value can be in any of these forms:
  - Binary <<153, 77, 63>>
  - List [153, 77, 63]
  - An Elixir type which can be directly encoded to 4-byte binary value

  Key:
  MSB = Most significant byte
  LSB = Least singificant byte
  """
  def midi(%{midi: value}) when is_binary(value) and byte_size(value) == 3, do: {?m, <<0>> <> value} # might be wrong approach, prepending 0
  def midi(%{midi: value}) when is_binary(value) and byte_size(value) == 4, do: {?m, value}
  def midi(%{midi: value}) when is_list(value) and length(value) == 3, do: {?m, :binary.list_to_bin([0] ++ value)}
  def midi(%{midi: value}) when is_list(value) and length(value) == 4, do: {?m, :binary.list_to_bin(value)}
  def midi(%{midi: value}), do: {?m, <<value::binary-size(4)>>}

  @doc section: :type
  @doc """
  Integer: 32-bit two’s complement big-endian or 64 bit big-endian two’s complement integer

  This function encodes Elixir's integer types as follows:

  | Type           | Lower value | Upper value | Comment |
  | -------------- | ----------- | ----------- | ------- |
  | 32 bit integer | -2_147_483_647 | 2_147_483_647 | This is 2^31 rounded |
  | 64 bit integer | -9_223_372_036_854_775_808 | 9_223_372_036_854_775_808 | This is 2^63 rounded |
  """
  @default_integer_size 2_147_483_647 # 2^31 rounded
  @two_complement_integer_size 9_223_372_036_854_775_808 # 2^63 rounded
  def integer(value) when is_integer(value) and abs(value) < @default_integer_size, do: {?i, <<value::big-size(32)>>}
  def integer(value) when is_integer(value) and abs(value) < @two_complement_integer_size, do: {?h, <<value::big-size(64)>>}


  @doc section: :type
  @doc """
  Char: Encode a character as 32 bit.

  In OSC 1.0, the Char type is optional and is used to encode an ascii character in 32 bits.

  This function accepts a map `%{char: value}` as the first parameter, where value can be a
  - single character string (e.g. "A")
  - single char ~c"A"
  - an integer representing an ASCII char.

  ## Example
  All of the following are equivalent for the ASCII 'A' character:
  ```
  iex> %{char: "A"} |> OSCx.Encoder.char()
  {99, <<0, 0, 0, 65>>}

  iex-> %{char: ~c"A"} |> OSCx.Encoder.char()
  {99, <<0, 0, 0, 65>>}

  iex-> %{char: 'A'} |> OSCx.Encoder.char()
  {99, <<0, 0, 0, 65>>}

  iex-> %{char: 65} |> OSCx.Encoder.char()
  {99, <<0, 0, 0, 65>>}
  ```
  """
  def char(%{char: value}) when is_integer(value), do: {?c, <<value::utf32>>}
  def char(%{char: value}) when is_binary(value) and byte_size(value) == 1, do: {?c, <<:binary.first(value)::utf32>>}
  def char(%{char: value}) when is_list(value) and length(value) == 1, do: {?c, <<List.first(value)::utf32>>}



  @doc section: :type
  @doc """
  RGBA: Encides a 32-bit RGBA color.

  Takes as it's first parameter an `%{rgba: [r, g, b, a]}` map.

  The map contains 4 integer values, repesenging R, G, B and A in that order.

  ## Example
  ```
  iex> OSCx.Encoder.rgba(%{rgba: [255, 255, 60, 20]})
  {114, <<255, 255, 60, 20>>}

  ```
  """
  def rgba(%{rgba: [r,g,b,a]=value}) when is_list(value) and length(value) == 4, do: {?r, <<r::integer, g::integer, b::integer, a::integer>>}

  @doc section: :type
  @doc """
  OSC-timetag: 64 bit, big-endian, fixed-point floating point number

  Takes a map in the format `%{seconds: seconds, fraction: fraction}`.

  The OSC Specification defines a time tag as a 64-bit fixed-point number that represents a time in seconds since midnight on January 1, 1900.
  The first 32 bits of the timetag represent the number of seconds, and the last 32 bits represent fractional parts of a second to a precision of about 200 picoseconds.
  """
  def time(%{seconds: seconds, fraction: fraction}), do: {?t, <<seconds::big-size(32), fraction::big-size(32)>>}

  @doc section: :type
  @doc """
  Float: 32-bit big-endian IEEE 754 floating point number, or 64 bit (“double”) IEEE 754 floating point number.

  This function encodes Elixir's float types as follows:

  | Type           | Lower value | Upper value |
  | -------------- | ----------- | ----------- |
  | 32 bit float | 1.175494351e-38 | 3.402823466e+38 |
  | 64 bit float | 2.2250738585072014e-308 | 1.7976931348623158e+308 |

  Note the ranges in this table are approximate.
  """
  @default_float_range_lower 1.175494351e-38
  @default_float_range_upper 3.4028234663852886e38
  @default_double_range_lower 2.2250738585072014e-308
  @default_double_range_upper 1.7976931348623158e+308
  def float(value) when is_float(value) and value <= @default_float_range_upper and value >= @default_float_range_lower, do: {?f, <<value::big-float-size(32)>>}
  def float(value) when is_float(value) and value <= @default_double_range_upper and value >= @default_double_range_lower, do: {?d, <<value::big-float-size(64)>>}


  @doc section: :type
  @doc """
  OSC-string: a sequence of non-null ASCII characters followed by 1-4 null characters – total string bytes must be a multiple of 4
  """
  def string(value) when is_bitstring(value), do: {?s, pad(value) |> List.to_string()}


  @doc section: :type
  @doc """
  OSC-symbol: an alternative to strings in OSC systems, used for 'symbols' which are conceptually equivalent to Atoms in Elixir.
  """
  def symbol(value) when is_atom(value), do: {?S, value |> to_string() |> pad() |> List.to_string()}

  @doc section: :type
  @doc """
  OSC-blob: a 32-bit size count followed by that many bytes of arbitrary binary data (total must be a multiple of 4) – flexibility to send any encoding
  """
  def blob(value) when is_binary(value) do
    {?b, value |> prefix_size() |> pad()}
  end

  @doc section: :type
  @doc """
  Converts a list of encoded arguments to an OSC type tag string. Can also take a single encoded argument.
  """
  def type_tag_string(encoded_arg_tuple) when is_tuple(encoded_arg_tuple) do
    elem(encoded_arg_tuple, 0)
  end
  def type_tag_string(encoded_arg_list) when is_list(encoded_arg_list) do
    encoded_arg_list
    |> Enum.map(&type_tag_string(&1))
    |> List.to_string()
  end

  ## --------------
  ## TAG SPECIFIC
  ## --------------

  @doc section: :helper
  @doc """
  A helper function to encode a tag based on an Elixir type or special atom.

  This function accepts the following Elixir types and returns the equivalent OSC string tag type character as below:

  | Elixir value | OSC type | Character returned for OSC string tag type |
  | true | True | T |
  | false | False | F |
  | nil | Null | N |
  | :null | Null | N |
  | :impulse | Impulse (also known as Infinitum in OSC 1.0 Spec, or 'Bang') | I |
  """
  def tag(values) when is_list(values), do: Enum.map(values, &tag(&1)) |> List.to_string()
  def tag(true), do: tag_true()
  def tag(false), do: tag_false()
  def tag(nil), do: tag_null()
  def tag(:null), do: tag_null()
  def tag(:impulse), do: tag_impulse()
  def tag(_), do: <<>>

  @doc section: :tag
  @doc """
  Used to encode *true* into the tag type string.

  True equates to the charater 'T'.
  """
  def tag_true, do: ?T

  @doc section: :tag
  @doc """
  Used to encode *false* into the tag type string.

  True equates to the charater 'F'.
  """
  def tag_false, do: ?F

  @doc section: :tag
  @doc """
  Used to encode *null* into the tag type string.

  True equates to the charater 'N'.
  """
  def tag_null, do: ?N

  @doc section: :tag
  @doc """
  Used to encode *impulse* into the tag type string.

  Impulse is also known as Infinitum in OSC 1.0 Spec, or 'Bang'.

  True equates to the charater 'I'.
  """
  def tag_impulse, do: ?I


  ## -------
  ## HELPERS
  ## -------

  @doc section: :helper
  @doc """
  Returns the encoded values from the encoded argument list.

  e.g. returns the `value` from the `{type, value}` tuple as a list.
  """
  def encoded_value(encoded_arg) when is_tuple(encoded_arg) do
    elem(encoded_arg, 1)
  end
  def encoded_value(encoded_arg_list) when is_list(encoded_arg_list) do
    Enum.map(encoded_arg_list, &encoded_value(&1))
  end

  @doc section: :helper
  @doc """
  Adds padding to a value based on it's size.

  This is used for types of variable length so that they're equal to 4-bytes in length, or a mutuple of 4-bytes.
  """
  def pad(value) do
    case rem(:erlang.iolist_size(value), 4) do
      0 -> [value,<<0>>,<<0>>,<<0>>,<<0>>]
      1 -> [value,<<0>>,<<0>>,<<0>>]
      2 -> [value,<<0>>,<<0>>]
      3 -> [value,<<0>>]
    end
  end

  @doc section: :helper
  @doc """
  Used for prepending the size of a value.

  This is mainly used for prepending the size of a binary.

  The size is encoded in 32 bits, but this can be overridden when needed.
  """
  def prefix_size(value, size \\ 32) do
    byte_size = :erlang.iolist_size(value)
    <<byte_size::big-size(size)>> <> value
  end

end
