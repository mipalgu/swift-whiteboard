# Concurrency

The ``Whiteboard`` offers high-performance, lock-free access to shared memory for an arbitrary number of concurrent readers and a single writer for each message type at any given time.  This provides the ability for a writer to broadcast state messages with pull semantics to a large number of readers.

## Sphere of Control

A key concept behind the whiteboard architecture is the ability for readers and writers to determine the timing of ``post(message:)`` and ``getMessage()`` operations.  In other words, the timing of these operations remains in the sphere of control of the subsystem accessing the corresponding message, rather than creating a task synchronisation point.  This allows subsystems to remain de-coupled while providing fully concurrent message access.

## State Messages

The semantics of the whiteboard is that of a shared memory structure.  This means that multiple reads from the same location will yield the same value until a new message has been posted to this location by a writer.  Conversely, only the latest value that was posted will be visible on the whiteboard.  Therefore, readers are only guaranteed to see every message that was posted if they read at least as frequently as the corresponding writer posts their messages.

In general, it is recommended that any message that gets posted is a state message, i.e., it conveys the full information (state) the writer wants to convey.  For example a value `currentTemperature` that captures the latest temperature measurement constitutes a state message.  By contrast a value `temperatureChange` that contains the difference between the previous and current measurements constitutes an event message capturing the difference between a previous and current state (temperature).  Event messages are not recommended, as they require knowledge of both the previous value (state) as well as the difference (change) to determine current value (state), which makes them more sensitive to message loss.
