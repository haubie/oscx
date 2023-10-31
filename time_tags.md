# Time tags and synchronisation

The purpose of this page is to document:

- Summarise timing in OSC
- Describe the role of the OSC time tag
- Descibe how timing is used when processing OSC Bundles and Messages.

It draws heavily from the the Temporal Semantics and OSC Time Tags section of the [OpenSoundControl Specification 1.0](https://opensoundcontrol.stanford.edu/spec-1_0.html).

## Summary
- OSC doesn't offer clock synchronization. It does offer a way to encode timing information though OSC time tags.

- When an OSC packet has a single message, the server should process it immediately. If it's a bundle, the time tag within the bundle determines when to process the contained messages.

- Time tags are represented as 64-bit fixed point numbers, with the first 32 bits indicating seconds since January 1, 1900, and the last 32 bits representing fractional seconds. To represent a time-tag, this library uses a map of `%{seconds: seconds, fraction: fraction}` where `seconds` and `fraction` are 32-bit integers, or `%{time: value}` where `value` is a 64-bit integer.

- If a time tag has 63 zero bits followed by a one, it means "immediately".

- Messages in the same bundle should be processed one after the other without interruption.

- The order of method invocation is unspecified when an address pattern is dispatched to multiple methods. But messages within a bundle should be processed in the order they appear in the packet.

- Bundles within bundles must have time tags greater than or equal to their enclosing bundle. The atomicity requirement for messages in the same bundle doesn't apply to bundles within a bundle.

## Time management
An OSC (Open Sound Control) server relies on access to accurate time data but it lacks built-in clock synchronization mechanisms. OSC servers need to work with precise time values for efficient operation. This is where OSC time tags come in.

OSC time tags are represented as 64-bit fixed point numbers, where the:
- first 32 bits specify the number of seconds elapsed since midnight on January 1, 1900
- last 32 bits represent fractional parts of a second with high precision, approximately 200 picoseconds.

To signal immediate exection, a time tag can be created with a value comprising 63 zero bits followed by a one in the least significant bit. In this library you can use `%{time: :immediate}` for this purpose.

### Formatting time in this library
A time tag in this library is represented by a map. There are two different versions, depending on your needs:
- Map with a 64-bit fixed point number:
```
%{time: value}
```
- Map with 32-bit integers representing seconds and fraction of a second:
```
%{seconds: seconds, fraction: fraction}
```

See `OSCx.Encoder.time/1` and `OSCx.Decoder.time/2` for more information. 

## Message processing
When receiving an OSC packet, the behaviour differs based on its content:

- #### Single OSC Message
  If an incoming OSC packet contains only a single OSC message, the OSC server should promptly invoke the corresponding OSC method, processing it without delay.

- #### OSC Bundle
  When the packet contains an OSC bundle, the time tag associated with the bundle determines when the bundled OSC messages' corresponding methods should be invoked.
  
  If the time represented by the time tag is equal to or earlier than the current time, the OSC server should process the messages immediately. However, if the time tag indicates a future time, the OSC server must store the bundle until the specified time is reached and then execute the appropriate OSC methods.

  - Atomic Message Processing: Messages within the same OSC bundle are treated as atomic units. Their corresponding OSC methods should be invoked consecutively, without any other processing occurring between these method invocations.

  - Order of Method Invocation: When an OSC address pattern is dispatched to multiple OSC methods, the order in which these matching methods are invoked is not specified. However, when an OSC bundle contains multiple OSC messages, the methods corresponding to these messages must be invoked in the same order as the messages appear in the packet.

    See [Order of invocation example](https://opensoundcontrol.stanford.edu/spec-1_0-examples.html#bundledispatchorder) in the OSC Spec.

  - Nested Bundles: In the case of bundles within bundles, it's important to note that the OSC time tag of the enclosed bundle must be greater than or equal to the OSC time tag of the enclosing bundle. It's worth mentioning that the atomicity requirement for OSC messages in the same bundle does not apply to OSC bundles within an OSC bundle.

## More information
- [README file](README.md)
- [Arguments and types](arguments_and_types.md)
- Temporal Semantics and OSC Time Tags section of the [OpenSoundControl Specification 1.0](https://opensoundcontrol.stanford.edu/spec-1_0.html).
