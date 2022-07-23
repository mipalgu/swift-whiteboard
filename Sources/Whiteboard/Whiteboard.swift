//
//  Whiteboard.swift
//
//  Created by Rene Hexel on 23/7/2022.
//
import Foundation
import cwhiteboard

/// A simple whiteboard class that allows non-blocking put and get operations.
/// This whiteboard is safe for concurrent reader access, provided that there
/// there is only a single writer attempting to access the whiteboard at any
/// given time.
public final class Whiteboard: Sendable {
    /// Descriptor of the underlying whiteboard
    @usableFromInline
    let wbd: UnsafeMutablePointer<gu_simple_whiteboard_descriptor>

    deinit {
        gsw_free_whiteboard(wbd)
    }

    /// Designated initialiser for a whiteboard using the default name.
    /// - Note: the default name is taken from the `WHITEBOARD_NAME` environment variable
    /// and will revert to the value of `GSW_DEFAULT_NAME` if undefined.
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

    /// Return a pointer to the current message for the given slot index
    /// - Parameter slot: Slot number for the returned message
    /// - Returns: A pointer to the current message in the given slot
    @inlinable
    public func currentMessagePointer<MessageType, Slot: WhiteboardSlot>(for slot: Slot) -> UnsafeMutablePointer<MessageType>! {
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

    /// Return a pointer to  the next message for the given slot index
    /// - Parameter slot: Slot for the returned message
    /// - Returns: A pointer to the next message in the given slot
    @inlinable
    public func nextMessagePointer<MessageType, Slot: WhiteboardSlot>(for slot: Slot) -> UnsafeMutablePointer<MessageType>! {
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
    /// - Parameter slot: Slot  for the given message whose generation should be incremented
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
    /// - Parameter slot: Slot number for the given message whose generation should be incremented
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
}
