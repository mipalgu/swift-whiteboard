//
//  Whiteboard.swift
//
//  Created by Rene Hexel on 23/7/2022.
//

import cwhiteboard
import Foundation

/// A simple whiteboard class that allows non-blocking put and get operations.
/// This whiteboard is safe for concurrent reader access, provided that there
/// there is only a single writer attempting to access the whiteboard at any
/// given time.
public final class Whiteboard: Sendable {
    /// Static version of the whiteboard.
    ///
    /// This is the version of the whiteboard that was visible when this package was compiled.
    /// - Note: For safety, an application should check that this version is equal to
    ///         the dynamic `version` of the whiteboard.
    public static var version = Int(GU_SIMPLE_WHITEBOARD_VERSION)

    /// Total number of message slots available on the whiteboard.
    ///
    /// Slot indices range from 0 ..< `slotCount`.
    public static var slotCount = Int(GSW_TOTAL_MESSAGE_TYPES)

    /// Descriptor of the underlying whiteboard
    @usableFromInline let wbd: UnsafeMutablePointer<gu_simple_whiteboard_descriptor>

    /// Dynamic version of the whiteboard as recorded in shared memory.
    ///
    /// This is the version of the whiteboard recorded by the process creating the
    /// shared memory file.  If the whiteboard was created by the current process,
    /// this version will match the static version created at compile time.
    /// - Note: For safety, an application should check that this version
    ///         is equal to the static `version` of the whiteboard.
    @inlinable public var version: Int { Int(wbd.pointee.wb.pointee.version) }

    /// Global whiteboard event counter.
    ///
    /// This contains the global number of message postings that have happened so far.
    /// Checking for equality with a previous value can be used to determine
    /// if new messages are available on the whiteboard.
    /// - Note: This counter will wrap around to zero frequently, most likely before it reaches `Int.max`
    @inlinable public var eventCount: Int { Int(wbd.pointee.wb.pointee.eventcount) }

    /// Designated initialiser for a whiteboard using the default name.
    /// - Note: the default name is taken from the `WHITEBOARD_NAME` environment variable
    /// and will revert to the value of `GSW_DEFAULT_NAME` ("whiteboard") if undefined.
    @inlinable
    public init() {
        if let name = getenv(GSW_DEFAULT_ENV) {
            wbd = gsw_new_simple_whiteboard(name)
        } else {
            wbd = gsw_new_simple_whiteboard(GSW_DEFAULT_NAME)
        }
    }

    /// Designated initialiser for a whiteboard with the given name.
    /// - Parameter name: The name of the whiteboard to create
    @inlinable
    public init(name: UnsafePointer<CChar>) {
        wbd = gsw_new_simple_whiteboard(name)
    }

    /// Return a pointer to  the current whiteboard message for the returned message type
    /// - Returns: A pointer to the next message in the given slot
    /// - Note: This function uses messages conforming to `WhiteboardSlotted` and is therefore type safe.
    @inlinable
    public func currentMessagePointer<MessageType: WhiteboardSlotted>() -> UnsafeMutablePointer<MessageType>! {
        UnsafeMutableRawPointer(
                gsw_current_message(wbd.pointee.wb, CInt(MessageType.whiteboardSlot.rawValue))
            )?.assumingMemoryBound(to: MessageType.self)
    }

    /// Return a pointer to the current message for the given slot index
    /// - Parameter slot: A `WhiteboardSlot` whose `rawValue` is the slot number for the message to post
    /// - Returns: A pointer to the current message in the given slot
    @inlinable
    public func currentMessagePointer<MessageType, Slot: WhiteboardSlot>(
        for slot: Slot
    ) -> UnsafeMutablePointer<MessageType>! {
        currentMessagePointer(forSlotAtIndex: CInt(slot.rawValue))
    }

    /// Return a pointer to the current message for the given slot index
    /// - Parameter slot: Slot number for the returned message
    /// - Returns: A pointer to the current message in the given slot
    /// - Note: This function uses a numerical index and is not recommended, except for low-level usage.
    /// For high-level usage, use `currentMessagePointer<MessageType>(for slot:)` instead.
    @inlinable
    public func currentMessagePointer<MessageType>(forSlotAtIndex slot: CInt) -> UnsafeMutablePointer<MessageType>! {
        UnsafeMutableRawPointer(gsw_current_message(wbd.pointee.wb, slot))?.assumingMemoryBound(to: MessageType.self)
    }

    /// Return a pointer to  the next message for the given message type
    /// - Returns: A pointer to the next message in the given slot
    /// - Note: This function uses messages conforming to `WhiteboardSlotted` and is therefore type safe.
    @inlinable
    public func nextMessagePointer<MessageType: WhiteboardSlotted>() -> UnsafeMutablePointer<MessageType>! {
        UnsafeMutableRawPointer(
                gsw_next_message(wbd.pointee.wb, CInt(MessageType.whiteboardSlot.rawValue))
            )?.assumingMemoryBound(to: MessageType.self)
    }

    /// Return a pointer to  the next message for the given slot index
    /// - Parameter slot: A `WhiteboardSlot` whose `rawValue` is the slot number for the message to post
    /// - Returns: A pointer to the next message in the given slot
    @inlinable
    public func nextMessagePointer<MessageType, Slot: WhiteboardSlot>(
        for slot: Slot
    ) -> UnsafeMutablePointer<MessageType>! {
        nextMessagePointer(forSlotAtIndex: CInt(slot.rawValue))
    }

    /// Return a pointer to  the next message for the given slot index
    /// - Parameter slot: Slot number for the returned message
    /// - Returns: A pointer to the next message in the given slot
    /// - Note: This function uses a numerical index and is not recommended, except for low-level usage.
    /// For high-level usage, use `nextMessagePointer<MessageType>(for slot:)` instead.
    @inlinable
    public func nextMessagePointer<MessageType>(forSlotAtIndex slot: CInt) -> UnsafeMutablePointer<MessageType>! {
        UnsafeMutableRawPointer(gsw_next_message(wbd.pointee.wb, slot))?.assumingMemoryBound(to: MessageType.self)
    }

    /// Increment the ring buffer generation number for the given message slot
    /// - Parameter slot: A `WhiteboardSlot` whose `rawValue` is the slot number for the message to post
    /// - Note: The generation will wrap around to zero once `GU_SIMPLE_WHITEBOARD_GENERATIONS` have been reached.
    @inlinable
    public func incrementGeneration<Slot: WhiteboardSlot>(for slot: Slot) {
        gsw_increment(wbd.pointee.wb, CInt(slot.rawValue))
    }

    /// Increment the ring buffer generation number for the given message slot
    /// - Parameter slot: Slot number for the given message whose generation should be incremented
    /// - Note: The generation will wrap around to zero once `GU_SIMPLE_WHITEBOARD_GENERATIONS` have been reached.
    /// - Note: This function uses a numerical index and is not recommended, except for low-level usage.
    /// For high-level usage, use `incrementGeneration(for slot:)` instead.
    @inlinable
    public func incrementGeneration(forSlotAtIndex slot: CInt) {
        gsw_increment(wbd.pointee.wb, slot)
    }

    /// Increment the event counter for the given message slot
    /// - Parameter slot: A `WhiteboardSlot` whose `rawValue` is the slot number for the message to post
    /// - Note: the event counter will wrap around to zero on overflow
    @inlinable
    public func incrementEventCounter<Slot: WhiteboardSlot>(for slot: Slot) {
        gsw_increment_event_counter(wbd.pointee.wb, CInt(slot.rawValue))
    }

    /// Increment the event counter for the given message slot
    /// - Parameter slot: Slot number for the given message whose generation should be incremented
    /// - Note: the event counter will wrap around to zero on overflow
    /// - Note: This function uses a numerical index and is not recommended, except for low-level usage.
    /// For high-level usage, use `incrementEventCounter(for slot:)` instead.
    @inlinable
    public func incrementEventCounter(forSlotAtIndex slot: CInt) {
        gsw_increment_event_counter(wbd.pointee.wb, slot)
    }

    /// Post the given message to the whiteboard
    /// - Parameters:
    ///   - message: The message to post
    ///   - slotIndex: Slot number for the message to post
    /// - Note: This function uses a numerical index and is not recommended, except for low-level usage.
    /// For high-level usage, use messages conforming to `WhiteboardSlotted` or  `post(message:to:)` instead.
    @inlinable
    public func post<MessageType>(message: MessageType, toSlotAtIndex slotIndex: CInt) {
        assert(MemoryLayout<MessageType>.size <= GU_SIMPLE_WHITEBOARD_BUFSIZE)
        nextMessagePointer(forSlotAtIndex: slotIndex).pointee = message
        incrementGeneration(forSlotAtIndex: slotIndex)
        incrementEventCounter(forSlotAtIndex: slotIndex)
    }

    /// Post the given message to the whiteboard
    /// - Parameters:
    ///   - message: The message to post
    ///   - slot: A `WhiteboardSlot` whose `rawValue` is the slot number for the message to post
    /// - Note: This function uses a `WhiteboardSlot` index and is not type safe.
    /// For type-safe usage, use messages conforming to `WhiteboardSlotted` instead.
    @inlinable
    public func post<MessageType, Slot: WhiteboardSlot>(message m: MessageType, to slot: Slot) {
        post(message: m, toSlotAtIndex: CInt(slot.rawValue))
    }

    /// Post the given message to the whiteboard
    /// - Parameter message: The message to post
    /// - Note: This function uses messages conforming to `WhiteboardSlotted` and is therefore type safe.
    @inlinable
    public func post<MessageType: WhiteboardSlotted>(message m: MessageType) {
        post(message: m, to: MessageType.whiteboardSlot)
    }

    /// Post the content of the memory pointed to by the given message pointer to the whiteboard
    /// - Parameters:
    ///   - pointer: Pointer to the message to post
    ///   - slotIndex: Slot number for the message to post
    /// - Note: This function uses a numerical index and is not recommended, except for low-level usage.
    /// For high-level usage, use messages conforming to `WhiteboardSlotted` or  `post(messageReferencedBy:to:)`
    /// instead.
    @inlinable
    public func post<MessageType>(
        messageReferencedBy pointer: UnsafePointer<MessageType>,
        toSlotAtIndex slotIndex: CInt
    ) {
        assert(MemoryLayout<MessageType>.size <= GU_SIMPLE_WHITEBOARD_BUFSIZE)
        nextMessagePointer(forSlotAtIndex: slotIndex).pointee = pointer.pointee
        incrementGeneration(forSlotAtIndex: slotIndex)
        incrementEventCounter(forSlotAtIndex: slotIndex)
    }

    /// Post the given message to the whiteboard
    /// - Parameters:
    ///   - pointer: Pointer to the message to post
    ///   - slot: A `WhiteboardSlot` whose `rawValue` is the slot number for the message to post
    /// - Note: This function uses a `WhiteboardSlot` index and is not type safe.
    /// For type-safe usage, use pointers to messages conforming to `WhiteboardSlotted` instead.
    @inlinable
    public func post<MessageType, Slot: WhiteboardSlot>(
        messageReferencedBy pointer: UnsafePointer<MessageType>,
        to slot: Slot
    ) {
        post(messageReferencedBy: pointer, toSlotAtIndex: CInt(slot.rawValue))
    }

    /// Post the given message to the whiteboard
    /// - Parameter message: The message to post
    /// - Note: This function uses messages conforming to `WhiteboardSlotted` and is therefore type safe.
    @inlinable
    public func post<MessageType: WhiteboardSlotted>(messageReferencedBy pointer: UnsafePointer<MessageType>) {
        post(messageReferencedBy: pointer, to: MessageType.whiteboardSlot)
    }

    /// Post a contiguous array of elements to the whiteboard slot with the given numerical index
    /// - Parameters:
    ///   - array: The array of elements to post together with its count of elements
    ///   - slotIndex: Slot number for the message to post
    /// - Note: This function records the number of elements on the whiteboard,
    ///         but uses a numerical index and thus is not recommended, except for low-level usage.
    /// For high-level usage, use messages conforming to `WhiteboardSlotted` or  `post(elements:to:)` instead.
    @inlinable
    public func post<MessageType>(array: [MessageType], toSlotAtIndex slotIndex: CInt) {
        let arrayCount = array.count
        assert(MemoryLayout<MessageType>.stride * arrayCount <= Int(GU_SIMPLE_WHITEBOARD_BUFSIZE) - MemoryLayout<UInt16>.stride)
        // swiftlint:disable:next force_unwrapping
        let ptr = UnsafeMutableRawPointer(gsw_next_message(wbd.pointee.wb, slotIndex))!
        ptr.assumingMemoryBound(to: UInt16.self).pointee = UInt16(arrayCount)
        let base: UnsafeMutablePointer<MessageType> = (ptr + MemoryLayout<UInt16>.stride)
            .assumingMemoryBound(to: MessageType.self)
        if array.withContiguousStorageIfAvailable({
            // swiftlint:disable:next force_unwrapping
            base.initialize(from: $0.baseAddress!, count: arrayCount)
        }) == nil {
            for i in 0..<arrayCount {
                base[i] = array[i]
            }
        }
        incrementGeneration(forSlotAtIndex: slotIndex)
        incrementEventCounter(forSlotAtIndex: slotIndex)
    }

    /// Post a contiguous array of elements to the whiteboard slot with the given numerical index
    /// - Parameters:
    ///   - array: The array of elements to post together with its count of elements
    ///   - slotIndex: Slot number for the message to post
    /// - Note: This function records the number of elements on the whiteboard,
    ///         but uses a numerical index and thus is not recommended, except for low-level usage.
    /// For high-level usage, use messages conforming to `WhiteboardSlotted` or  `post(elements:to:)` instead.
    @inlinable
    public func post<MessageType, Slot: WhiteboardSlot>(array a: [MessageType], to slot: Slot) {
        post(array: a, toSlotAtIndex: CInt(slot.rawValue))
    }

    /// Post elements to the whiteboard to the whiteboard slot with the given numerical index
    /// - Parameters:
    ///   - elements: The buffer of elements to post
    ///   - slotIndex: Slot number for the message to post
    /// - Note: This function uses a numerical index and does not record the number of elements on the whiteboard
    ///         and thus is not recommended, except for low-level usage.
    /// For high-level usage, use messages conforming to `WhiteboardSlotted` or  `post(elements:to:)` instead.
    @inlinable
    public func post<MessageType>(elements: UnsafeBufferPointer<MessageType>, toSlotAtIndex slotIndex: CInt) {
        assert(MemoryLayout<MessageType>.stride * elements.count <= GU_SIMPLE_WHITEBOARD_BUFSIZE)
        if let elementsBase = elements.baseAddress {
            let base: UnsafeMutablePointer<MessageType> = nextMessagePointer(forSlotAtIndex: slotIndex)
            base.initialize(from: elementsBase, count: elements.count)
        }
        incrementGeneration(forSlotAtIndex: slotIndex)
        incrementEventCounter(forSlotAtIndex: slotIndex)
    }

    /// Post elements to the whiteboard to the given whiteboard slot
    /// - Parameters:
    ///   - elements: The buffer of elements to post
    ///   - slotIndex: Slot number for the message to post
    /// - Note: This function does not record the number of elements on the whiteboard.
    /// For high-level usage, use messages conforming to `WhiteboardSlotted` or  `post(elements:to:)` instead.
    @inlinable
    public func post<MessageType, Slot: WhiteboardSlot>(elements es: UnsafeBufferPointer<MessageType>, to slot: Slot) {
        post(elements: es, toSlotAtIndex: CInt(slot.rawValue))
    }

    /// Get a message from the whiteboard
    /// - Parameter slotIndex: Slot number for the message to get
    /// - Returns: A copy of the current whiteboard message in the given slot
    /// - Note: This function uses a numerical index and is not recommended, except for low-level usage.
    /// For high-level usage, use messages conforming to `WhiteboardSlotted` or  `getMessage(from:)` instead.
    @inlinable
    public func getMessage<MessageType>(fromSlotAtIndex slotIndex: CInt) -> MessageType {
        currentMessagePointer(forSlotAtIndex: slotIndex).pointee
    }

    /// Get a message from the whiteboard
    /// - Parameter slot: A `WhiteboardSlot` whose `rawValue` is the slot number for the message to get
    /// - Returns: A copy of the current whiteboard message in the given slot
    /// - Note: This function uses a `WhiteboardSlot` index and is not type safe.
    /// For type-safe usage, use pointers to messages conforming to `WhiteboardSlotted` instead.
    @inlinable
    public func getMessage<MessageType, Slot: WhiteboardSlot>(from slot: Slot) -> MessageType {
        currentMessagePointer(for: slot).pointee
    }

    /// Get a message from the whiteboard
    /// - Parameter slot: A `WhiteboardSlot` whose `rawValue` is the slot number for the message to get
    /// - Returns: A copy of the current whiteboard message in the given slot
    /// - Note: This function uses messages conforming to `WhiteboardSlotted` and is therefore type safe.
    @inlinable
    public func getMessage<MessageType: WhiteboardSlotted>() -> MessageType {
        currentMessagePointer().pointee
    }

    /// Retrieve a buffer pointer to the current whiteboard message.
    ///
    /// The caller needs to ensure that the data within the whiteboard are copied
    /// prior to being updated by the writer.
    ///
    /// - Parameter slotIndex: Slot number for the message to get
    /// - Returns: A buffer pointer to the current whiteboard message in the given slot
    /// - Note: This function uses a numerical index and returns a static element count derived from the size of
    ///         a whiteboard message and each element and thus is not recommended, except for low-level usage.
    /// For high-level usage, use messages conforming to `WhiteboardSlotted` or  `getMessage(from:)` instead.
    @inlinable
    public func getElements<MessageType>(fromSlotAtIndex slotIndex: CInt) -> UnsafeBufferPointer<MessageType> {
        UnsafeBufferPointer(
            start: currentMessagePointer(forSlotAtIndex: slotIndex),
            count: Int(GU_SIMPLE_WHITEBOARD_BUFSIZE) / MemoryLayout<MessageType>.stride
        )
    }

    /// Retrieve a buffer pointer to the current whiteboard message.
    ///
    /// The caller needs to ensure that the data within the whiteboard are copied
    /// prior to being updated by the writer.
    ///
    /// - Parameter slotIndex: Slot number for the message to get
    /// - Returns: A buffer pointer to the current whiteboard message in the given slot
    /// - Note: This function uses a numerical index and returns a static element count derived from the size of
    ///         a whiteboard message and each element and thus is not recommended, except for low-level usage.
    /// For high-level usage, use messages conforming to `WhiteboardSlotted` or  `getMessage(from:)` instead.
    @inlinable
    public func getElements<MessageType, Slot: WhiteboardSlot>(from slot: Slot) -> UnsafeBufferPointer<MessageType> {
        getElements(fromSlotAtIndex: CInt(slot.rawValue))
    }

    /// Get an array of elements from the whiteboard slot with the given numerical index
    ///
    /// - Parameters:
    ///   - slotIndex: Slot number for the message to post
    /// - Returns: Array of elements containing the whiteboard message
    /// - Note: This function retrieves the recorded number of elements from the whiteboard,
    ///         but uses a numerical index and thus is not recommended, except for low-level usage.
    /// For high-level usage, use messages conforming to `WhiteboardSlotted` or  `post(elements:to:)` instead.
    @inlinable
    public func getArray<MessageType>(fromSlotAtIndex slotIndex: CInt) -> [MessageType] {
        // swiftlint:disable:next force_unwrapping
        let ptr = UnsafeMutableRawPointer(gsw_current_message(wbd.pointee.wb, slotIndex))!
        let arrayCount =
            min(Int(ptr.assumingMemoryBound(to: UInt16.self).pointee),
                (Int(GU_SIMPLE_WHITEBOARD_BUFSIZE) - MemoryLayout<UInt16>.stride) / MemoryLayout<MessageType>.stride)
        let base: UnsafeMutablePointer<MessageType> = (ptr + MemoryLayout<UInt16>.stride).assumingMemoryBound(to: MessageType.self)
        let array = [MessageType](unsafeUninitializedCapacity: arrayCount) { buffer, initializedCount in
            buffer.baseAddress?.initialize(from: base, count: arrayCount)
            initializedCount = arrayCount
        }
        return array
    }

    /// Get an array of elements from the whiteboard slot with the given numerical index.
    ///
    /// For higher performance, to read an array of raw bytes, use `getBytes(from:)` instead.
    ///
    /// - Parameters:
    ///   - slotIndex: Slot number for the message to post
    /// - Returns: Array of elements containing the whiteboard message
    /// - Note: This function retrieves the recorded number of elements from the whiteboard.
    @inlinable
    public func getArray<MessageType, Slot: WhiteboardSlot>(from slot: Slot) -> [MessageType] {
        getArray(fromSlotAtIndex: CInt(slot.rawValue))
    }

    deinit {
        gsw_free_whiteboard(wbd)
    }
}
