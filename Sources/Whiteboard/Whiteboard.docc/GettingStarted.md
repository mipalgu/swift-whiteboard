# Getting started with the Whiteboard

Create a Whiteboard, then read (get) or write (post) messages.

## Overview

A whiteboard is shared memory area structured into messages that can be written to and read from by multiple threads or processes.  Each whiteboard is memory-mapped to a named file so it can be accessed by unrelated processes and persist beyond the life-span of a process.

### Creating a Whiteboard

To create a whiteboard, you initialise a new instance of the ``Whiteboard/Whiteboard`` class.  Optionally, you can provide a name for the whiteboard, otherwise the created instance will access the global, default whiteboard, as the following code shows:

```swift
let whiteboard = Whiteboard()
```

If you want to give your whiteboard a unique name (shared between threads and processes that want to use this whiteboard), you pass in a name into the initialiser, e.g.:

```swift
let namedWhiteboard = Whiteboard(name: "special-whiteboard")
```

### Naming Considerations

All processes and threads sharing a whiteboard need to agree on the structure and semantics of each whiteboard message.  In other words, a whiteboard defines a data-centric view of inter-process communication.  This is particularly important for the default Global Whiteboard.  All processes and threads need to know the ABI and whiteboard slots (locations) of the data they access.  Processes that want to share different data sets can create their own whiteboards (using unique and distinct names) that correspond to the data structures and message slots they want to use.

### Defining Message Slots

The semantics of a whiteboard message is defined by its message slot.  In the underlying `gusimplewhiteboard` implementation, a message slot is simply a numerical index into the array of messages stored on the whiteboard.  In Swift, it is recommended to use an `enum` that is shared between the processes using the whiteboard and globally defines the whiteboard slot numbers to use.  This can be achieved by conforming to the ``WhiteboardSlot`` protocol:

```swift
enum GlobalWhiteboardSlot: Int, WhiteboardSlot {
    case interiorTemperature = 1
    case exteriorTemperature = 2
    case position = 3
    case velocity = 4
    case acceleration = 5
    case forwardActuatorPower = 10
}
```
Note: whether to specify explicit slot numbers (as in the example above) is a design decision.  They can assist with retaining specific slots over time as message types get added or removed from the system.

### Strongly Typed Messages

While the underlying whiteboard only provides a shared memory space for each message slot, it is important for all subsystems to agree on the ABI and semantics of these messages.  In Swift, this can be achieved by creating a `struct` that represents the data of a whiteboard message.  To assign a specific whiteboard slot to this message, conform it to the ``WhiteboardSlotted`` protocol that defines a static ``WhiteboardSlotted/whiteboardSlot`` property, corresponding to the slot number for that message:

```swift
struct ForwardActuatorPower: WhiteboardSlotted, Equatable {
    static let whiteboardSlot: GlobalWhiteboardSlot = .forwardActuatorPower
    let milliwatts: Int32
}
```
Note: for stored properties it is generally advisable to use types with clearly visible semantics (such as ``Int32`` for a signed 32-bit integer) over types (such as `Int`) whose size and ABI depends on additional factors such as host or CPU architecture (e.g. 32 bits vs 64 bits).

### Posting Messages

Posting a whiteboard message that conforms to ``WhiteboardSlotted`` is as simple as calling the ``Whiteboard/post(message:)`` method on the whiteboard, for example:

```swift
let forwardActuatorPower = ForwardActuatorPower(milliwatts: 123)
whiteboard.post(message: forwardActuatorPower)
```
Note: only a single writer can post to the whiteboard concurrently with any number of readers.  Multiple writers attempting to post concurrently results in undefined behaviour.

### Getting Messages

Retrieving a message from the whiteboard is as simple as calling the ``Whiteboard/getMessage()`` method on the whiteboard, for example:

```swift
let forwardActuatorPower: ForwardActuatorPower = whiteboard.getMessage()
```
Note: the slot of a ``WhiteboardSlotted`` message is determined by its type (through its static ``WhiteboardSlotted/whiteboardSlot`` property).

Any number of readers are allowed to retrieve messages concurrently from a whiteboard slot.  Ensure that the message you are trying to get has already been posted at least once to avoid reading random bits.  For more details and limits, see the section on Concurrency Considerations.