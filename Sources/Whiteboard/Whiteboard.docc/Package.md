# Whiteboard Package

A Swift shared-memory implementation of the blackboard knowledge base communication architecture.

## Overview

The Whiteboard package wraps the high-speed, concurrency-safe `gusimplewhiteboard` C library for use in Swift.  The package provides a sendable ``Whiteboard`` class that allows concurrent read and write access to a common message base.  Message slots can be configured by conforming to the ``WhiteboardSlot`` protocol.  You can create your own type-safe messages through conformance to the ``WhiteboardSlotted`` protocol.

## Topics

### Essentials

- <doc:GettingStarted>

### Message Slots

### Type-Safe Messaging

### Concurrency

### Low-level Interface
