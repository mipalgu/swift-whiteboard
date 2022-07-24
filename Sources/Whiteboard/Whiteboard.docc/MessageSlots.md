# Whiteboard Message Slots

The shared memory region that constitutes the whiteboard is subdivided into individual fixed and equal-size message slots.  For the whiteboard, this is simply a subdivision of memory that carries no semantic meaning.  The Swift ``Whiteboard Package`` inherits its sizes from the underlying [gusimplewhiteboard](https://github.com/mipalgu/gusimplewhiteboard) implementation.

## Slot Index

Valid slot indices have to be in range of 0 ..< ``Whiteboard/slotCount``.
While a slot index has to be an integer value within that range, it is advisable to use a type-safe alternative in Swift, such as a `RawRepresentable` `enum` whose `RawValue` represents the corresponding slot index.  This can be achieved by creating an `enum` that conforms to the `WhiteboardSlot` protocol, e.g.:

```swift
enum MyWhiteboardSlot: Int, WhiteboardSlot {
    case firstWhiteboardSlot
    case secondWhiteboardSlot
    case thirdWhiteboardSlot
    /* ... */
}
```
This enum can then be passed into the corresponding ``Whiteboard`` methods.  However, while less error-prone than using a hard-coded index number, there is still the danger of posting a whiteboard message to the wrong slot.  Strongly typed whiteboard messages are safer and avoid this problem altogether.

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
