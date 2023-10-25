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
  | **Integer** | a 32-bit signed integer |
  | **Float**   | a 32-bit IEEE 754 floating-point number |
  | **String**  | a sequence of printable ASCII characters |
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
  | t        | 116            | OSC time tag    | 1.1+ required    |
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
  """

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
  | Bitstring   | b            | 98             | Blob            |
  | -           | t            | 116            | OSC time tag    |
  | Integer (64 bit) | h       | 104            | 64-bit big-endian two’s complement integer |

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
  def encode_arg(value) when is_integer(value), do: integer(value)
  def encode_arg(value) when is_integer(value), do: integer(value)
  def encode_arg(value) when is_float(value), do: float(value)
  def encode_arg(value) when is_bitstring(value), do: String.printable?(value) && string(value) || blob(value)
  def encode_arg(value) when is_list(value), do: Enum.map(value, &encode_arg(&1))
  def encode_arg(_value), do: {:error, "Unknown type"}

  @doc section: :type
  @doc """
  32-bit integer: two’s complement, big-endian
  """
  @default_integer_size 2_147_483_647
  @two_complement_integer_size 9_223_372_036_854_775_808
  def integer(value) when is_integer(value) and abs(value) < @default_integer_size, do: {?i, <<value::big-size(32)>>}
  def integer(value) when is_integer(value) and abs(value) < @two_complement_integer_size, do: {?h, <<value::big-size(64)>>}

  @doc section: :type
  @doc """
  OSC-timetag: 64 bit, big-endian, fixed-point floating point number
  """
  def time(seconds, fraction), do: {?t, <<seconds::big-size(32), fraction::big-size(32)>>}

  @doc section: :type
  @doc """
  32-bit float: IEEE floating point encoding, big-endian
  """
  def float(value) when is_float(value), do: {?f, <<value::big-float-size(32)>>}

  @doc section: :type
  @doc """
  OSC-string: a sequence of non-null ASCII characters followed by 1-4 null characters – total string bytes must be a multiple of 4
  """
  def string(value) when is_bitstring(value), do: {?s, pad(value) |> List.to_string()}

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

  @doc section: :tag
  @doc """
  Encode a tag based on an Elixir type or special atom.

  This function accepts the following Elixir types and returns the equivalent OSC string tag type character as below:

  | Elixir value | OSC type | Character returned for OSC string tag type |
  | true | True | T |
  | false | False | F |
  | nil | Null | N |
  | :null | Null | N |
  | :impulse | Impulse | I |
  """
  def tag(true), do: tag_true()
  def tag(false), do: tag_false()
  def tag(nil), do: tag_null()
  def tag(:null), do: tag_null()
  def tag(:impulse), do: tag_impulse()

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

  True equates to the charater 'I'.
  """
  def tag_impulse, do: ?I


  ## HELPERS

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
  def pad(value) do
    case rem(:erlang.iolist_size(value), 4) do
      0 -> [value,<<0>>,<<0>>,<<0>>,<<0>>]
      1 -> [value,<<0>>,<<0>>,<<0>>]
      2 -> [value,<<0>>,<<0>>]
      3 -> [value,<<0>>]
    end
  end

  @doc section: :helper
  ## Default 32 bits for string and blobs, but packets are 64 bits
  def prefix_size(value, size \\ 32) do
    byte_size = :erlang.iolist_size(value)
    [<<byte_size::big-size(size)>>, value]
  end

end
