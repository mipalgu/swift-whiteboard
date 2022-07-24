# Whiteboard Message Slots

The shared memory region that constitutes the whiteboard is subdivided into individual fixed and equal-size message slots.  For the whiteboard, this is simply a subdivision of memory that carries no semantic meaning.  The Swift ``Whiteboard Package`` inherits its sizes from the underlying [gusimplewhiteboard](https://github.com/mipalgu/gusimplewhiteboard) implementation.

## Slot Index

Valid slot indices have to be in range of 0 ..< ``Whiteboard/slotCount``.
