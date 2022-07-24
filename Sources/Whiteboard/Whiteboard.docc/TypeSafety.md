# Type Safety

Swift is a strongly-typed language that allows to use safe, strongly typed messages on the whiteboard.

## Strongly Typed Whiteboard Messages

The ``Whiteboard`` library provides a ``WhiteboardSlotted`` protocol.  This protocol requires that conforming types expose a static ``whiteboardSlot`` property that contains the whiteboard slot for the corresponding message.  Here is an example:

```swift
struct MyMessage: WhiteboardSlotted, Equatable {
    /// The whiteboard slot allocated for messages of this type
    static let whiteboardSlot = MyWhiteboardSlot.firstWhiteboardSlot

    /// The actual value on the whiteboard
    let value: UInt64
}
```

### Multiple messages of the same kind

One potential issue with strongly typed whiteboard messages is that there could be multiple messages of the same kind, that would need to be posted to different whiteboard slots.  The way to achieve this is to separate the content type (message kind) from the semantic whiteboard type (determining the slot of the corresponding message).

Suppose you have a content type that represents a 2-dimensional screen coordinate, e.g.:

```swift
struct ScreenCoordinate: Sendable, Equatable {
    var x: Int16
    var y: Int16
}
```

Rather than making this screen coordinate conform to ``WhiteboardSlotted`` directly, we can now use composition to embed the coordinates in a corresponding whiteboard message.  For example, if we wanted to post two separate messages, say for the top left and bottom right coordinates of an object, we could the following whiteboard messages:

```swift
/// A message for the top left coordinate of an object
struct TopLeft: WhiteboardSlotted, Equatable {
    static let whiteboardSlot = MyWhiteboardSlot.secondWhiteboardSlot
    let coordinates: ScreenCoordinate
}

/// A message for the bottom right coordinate of an object
struct BottomRight: WhiteboardSlotted, Equatable {
    static let whiteboardSlot = MyWhiteboardSlot.thirdWhiteboardSlot
    let coordinates: ScreenCoordinate
}
```
