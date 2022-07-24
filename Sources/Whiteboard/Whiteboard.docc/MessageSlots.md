# Whiteboard Message Slots

The shared memory region that constitutes the whiteboard is subdivided into individual fixed and equal-size message slots.  For the whiteboard, this is simply a subdivision of memory that carries no semantic meaning.  The Swift ``Whiteboard`` inherits its sizes from the underlying [gusimplewhiteboard](https://github.com/mipalgu/gusimplewhiteboard) implementation.

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
This enum can then be passed into the corresponding ``Whiteboard`` methods.  However, while less error-prone than using a hard-coded index number, there is still the danger of posting a whiteboard message to the wrong slot.  Strongly typed whiteboard messages are safer and avoid this problem altogether. For details, see:

- <doc:TypeSafety>
