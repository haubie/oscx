![Midiex](assets/oscx-elixir-logo.png)

[![Documentation](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/oscx)
[![Package](https://img.shields.io/hexpm/v/oscx.svg)](https://hex.pm/packages/oscx)

OSCx is an Elixir library for encoding and decoding Open Sound Control (OSC) messages.

OSC is a flexible protocol that can be used for a wide variety of real-time tasks, such as controlling multimedia devices.

The API of this module is based on the older [osc_ex](https://github.com/camshaft/osc_ex) library.

Note that this library is deliberately minimilistic and no network transport or process logic is included.

## What is Open Sound Control (OSC)?
OSC is a network protocol for real-time communication between computers and other digital devices.
It is used to control sound synthesizers, lighting systems, and other multimedia devices.
OSC is a lightweight and flexible protocol that is well-suited for real-time applications.
OSC is an open standard, which means that anyone can develop software or hardware that supports OSC.

For more detailed information see [https://opensoundcontrol.stanford.edu/](https://opensoundcontrol.stanford.edu/index.html).

## OSC concepts
Below is a summary of key OSC concepts:

- #### Messages
  OSC messages are the basic unit of communication in OSC. They consist of an **address**, a **type tag**, and zero or more **arguments**.
  The address is a string that identifies the target of the message, such as `/my_synth/volume` or `/my_controller/button_1`.
  The type tag specifies the type of the arguments, which can be integers, floats, strings, or blobs of binary data.

  See `OSCx.Message`

- #### Bundles
  OSC bundles are a way to send multiple OSC messages in a single packet. This can be useful for improving performance or reducing bandwidth usage.

  See `OSCx.Bundle`

- #### Servers and Clients
  OSC servers listen for incoming OSC messages and clients send OSC messages. An application can be both a server and a client at the same time.

  See `OSCx.encode/1` and `OSCx.decode/1`

- #### Ports
  Although OSC is neutral of the transport layer, OSC messages are generally sent and received on UDP ports.

- #### Timetags
  OSC timetags can be used to synchronize OSC messages with other events. This is essential for applications such as audio and video production.

  See `OSCx.Encoder.time/2`

## OSC messages
OSC messages are made up of three parts:
1. **address** which represents the function you want to control starting with a forward slash e.g. `/status`
2. **tag type string** which lists the data types in the data payload, in the order they occur
3. **data payload** which could be any of the OSC types.

OSC messages can be transmitted over a variety of networks.

See the `OSCx.Message` module for more information.

## Installation

### Adding it to your Elixir project
The package can be installed by adding `oscx` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:oscx, "~> 0.1.0"}
  ]
end
```

### Using within Livebook and IEx
```elixir
Mix.install([{:oscx, "~> 0.1.0"}])
```

Documentation can be found at <https://hexdocs.pm/oscx>.

