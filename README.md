![Midiex](assets/oscx-elixir-logo.png)

[![Documentation](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/oscx)
[![Package](https://img.shields.io/hexpm/v/oscx.svg)](https://hex.pm/packages/oscx)

## About this library
OSCx is an Elixir library for encoding and decoding Open Sound Control (OSC) messages.

OSC is a flexible protocol that can be used for a wide variety of real-time tasks, such as controlling multimedia devices.

The API of this module is based on the older [osc_ex](https://github.com/camshaft/osc_ex) library. It was designed to be close to a 'drop in' replacement.

Note that this library is deliberately minimilistic and no network transport or process logic is included.

## What is Open Sound Control (OSC)?
OSC is a network protocol for real-time communication between computers and other digital devices.
It is used to control sound synthesizers, lighting systems, and other multimedia devices.
OSC is a lightweight and flexible that is well-suited for real-time applications.
OSC is an open standard, which means that anyone can develop software or hardware that supports OSC.

For more detailed information see [https://opensoundcontrol.stanford.edu/](https://opensoundcontrol.stanford.edu/index.html).

### Protocol or content format?
Because OSC does not define features typical of *protocols* such as command-response patterns, error handling or negotiation, it may be more accurate to describe OSC as a *content format*, like JSON or XML. An application that uses OSC only needs to be able to parse and encode to and from the OSC format.

None the less, its versatility makes it useful and why it's incorporated into music performance sofware such as [SuperCollider](https://supercollider.github.io/).

## OSC concepts
Below is a summary of key OSC concepts:

- #### Messages
  OSC messages are the basic unit of communication in OSC. They consist of an **address**, a **type tag**, and zero or more arguments:
  - The address is a string that identifies the target of the message, such as `/my_synth/volume` or `/my_controller/button_1`. This is very similar to the resource string or path seen in URLs.
  - The type tag specifies the type of the arguments, such as integers, floats, strings, or blobs of binary data. For more information see [arguments and types](arguments_and_types.md).

  See `OSCx.Message`.

- #### Bundles
  OSC bundles are a way to send multiple OSC messages in a single packet. This can be useful for improving performance or reducing bandwidth usage.

  See `OSCx.Bundle`.

- #### Servers and Clients
  OSC servers listen for incoming OSC messages and clients send OSC messages. An application can be both a server and a client at the same time.

  See `OSCx.encode/1` and `OSCx.decode/1` as well as the [OSCx Livebook tour](livebook/oscx_tour.livemd) which demonstrates sending and receiving OSC messages.

- #### Ports
  Although OSC is neutral of the transport layer, OSC messages are generally sent and received on UDP ports.

  See the [OSCx Livebook tour](livebook/oscx_tour.livemd) which demonstrates the use of UDP.

- #### Timetags
  OSC timetags can be used to synchronize OSC messages with other events. This is essential for applications such as audio and video production.
  
  OSC uses the same format as 64-bit Internet NTP timestamps, where the first 32 bits specify the number of seconds since midnight on January 1, 1900, and the last 32 bits specify fractional parts of a second to a precision of about 200 picoseconds. 

  See `OSCx.Encoder.time/1` and [Time tags and synchronisation](time_tags.md).

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

