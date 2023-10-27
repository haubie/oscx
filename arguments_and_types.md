# Arguments and types

The purpose of this page is to document:

- What arguments are
- Which types of arguments are recgonised by this library
- How Elixir types are encoded to OSC
- How OSC types are decoded to Elixir.

## About OSC arguments
Arguments represent the main data or 'payload' in an OSC message.

Arguments are typed. In an OSC message, the type of an argument is listed in the OSC tag type string, in the order the argument appears in the message.

![OSC message diagram](assets/osc-message.png)

OSC is encoded into 4-byte chunks. That is Ok for 32-bit data types are they are already of a 4-byte length, but for arbintary length data (like strings or blobs) padding with some null bytes may be needed to ensure each chunk is 4 bytes. 

The following diagram shows how each chunk is kept at exactly 4 bytes length, by adding padding where necesary:
```
Chunk 1: [D] [D] [D] [D]
Chunk 2: [D] [D] [D] [_]
Chunk 3: [D] [D] [_] [_]
Chunk 4: [D] [D] [D] [D]
```
*Key:* Where `[D]` is a byte of data and and `[_]` is a byte of empty padding.

## How Elixir types are encoded to OSC types
From Elixir, arguments are added to an OSC message using the `%OSCx.Message{}` struct. For example, below is a message with an integer of `2`, a float of `440.5` and a string `"phaser"`:
```
iex> %OSCx.Message{arguments: [2, 440.5, "phaser"]}
%OSCx.Message{address: "/", arguments: [2, 440.5, "phaser"], tag_types: []}
``` 
The following table shows how these and other Elixir types are encoded to OSC types:

| Elixir type      | Example                     | OSC type                                   | OSC spec version |
| ---------------- | --------------------------- | ------------------------------------------ | ---------------- |
| Integer (32 bit) | `2`                         | 32-bit integer                             | 1.0+ required    |
| Integer (64 bit) | `9_223_372_036_854_775_800` | 64-bit big-endian two’s complement integer | 1.0 non-standard |
| Float (32 bit)   | `440.5`                     | 32-bit float                               | 1.0+ required    |
| String           | `"phaser"`                  | String                                     | 1.0+ required    |
| Bitstring        | `<<1, 126, 40, 33>>`        | Blob                                       | 1.0+ required    |
| Atom             | `:loud`                     | Symbol                                     | 1.0 non-standard |
| Map with `:seconds` and `:fraction` keys | `%{seconds: ___, fraction: ___ }` | Time tag     | 1.1+ required    |
| Map with `:midi` key | `%{midi: ___ }`         | 4 byte MIDI message                        | 1.0 non-standard |
| List             | `[1, 2, 3]`                 | Array                                      | 1.0 non-standard |

## Non-argument data
There is also some data that isn't encoded as an argument, but rather, stored in the tag type string of the message. These are 'special types' and infrequently used:
- **True** (use `true` in Elixir)
- **False** (use `false` in Elixir)
- **Null** (use `nil` or `:null` in Elixir)
- **Impulse** (use `:impulse` in Elixir)

To include one of these tag types, just add them to `tag_types: []` in the `%OSCx.Message{}` struct, for example:
```
iex> iex> %OSCx.Message{tag_types: [true]}
%OSCx.Message{
  address: "/",
  arguments: [],
  tag_types: [true]
}

iex> iex> %OSCx.Message{tag_types: [:impulse]}
%OSCx.Message{
  address: "/",
  arguments: [],
  tag_types: [:impulse]
}
```

The following table shows how these special types types are encoded into the OSC type string:

| Elixir value                | OSC type                                   | OSC spec version |
| --------------------------- | ------------------------------------------ | ---------------- |
| `true`                      | True                                       | 1.1+ required    |
| `false`                     | False                                      | 1.1+ required    |
| `nil`                       | Null                                       | 1.1+ required    |
| `:null`                     | Null                                       | 1.1+ required    |
| `:impulse`                  | Impulse                                    | 1.1+ required    |


## How OSC types are decoded to Elixir types

### Decoding of arguments
Decoding is simply the reverse of the above, where the following OSC type becomes the equivalent Elixir type:
- Integer -> Integer
- Float -> Float
- String -> String
- Blob -> Bitstring (binary)
- Symbol -> Atom
- MIDI -> `%{midi: value}`
- Time tag -> `%{seconds: seconds, fraction: fraction}`
- Array -> List

#### Symbols, Atoms and Strings
By default, Symbols are converted to Elixir atoms. This behaviour can be changed to return a string instead. See `OSCx.Decoder.set_symbol_to_atom/1`.

### Decoding of special tag types
The special types of **True**, **False**, **Null**, **Impulse** will be decoded to `true`, `false`, `nil`, `:impulse` respectively an stored in `tag_types: []` in the `%OSCx.Message{}` struct, e.g.:
```
%OSCx.Message{
  address: "/",
  arguments: [],
  tag_types: [nil]
}
```
## More information
- [README file](README.md)
