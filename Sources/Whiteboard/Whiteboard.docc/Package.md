# Whiteboard Package

A Swift shared-memory implementation of the blackboard knowledge base communication architecture.

## Overview

The [Whiteboard Package](https://github.com/mipalgu/swift-whiteboard) wraps the high-speed, concurrency-safe [gusimplewhiteboard](https://github.com/mipalgu/gusimplewhiteboard) C library for use in Swift.  The package provides a sendable ``Whiteboard`` class that allows concurrent read and write access to a common message base.  Message slots can be configured by conforming to the ``WhiteboardSlot`` protocol.  You can create your own type-safe messages through conformance to the ``WhiteboardSlotted`` protocol.

## Topics

### Essentials

- <doc:GettingStarted>

### Message Slots

- <doc:MessageSlots>

### Type-Safe Messaging

- <doc:TypeSafety>

### Concurrency

- <doc:Concurrency>

### Low-level Interface

- <doc:LowLevel>
