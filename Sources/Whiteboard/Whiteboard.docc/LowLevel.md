# Interaction with the low-level C Whiteboard

It is important to keep in mind that the underlying C implementation does not sanity-check the values provided to its functions.  While this has performance benefits, it makes the interface potentially unsafe when provided with invalid parameters or messages that do not fit inside their allotted slots.  Fortunately, Swift is a type-safe language with safety by default and [gusimplewhiteboard](https://github.com/mipalgu/gusimplewhiteboard) exposes these fundamental limits.

In general, it is recommended to test these limits (e.g. through assertions) in relevant unit tests as well as integration tests.

## Whiteboard Version

The ``Whiteboard/Whiteboard`` class contains both a static and a dynamic ``version`` property.  For safe operation, it is imperative that an application checks at runtime that both versions are the same.

