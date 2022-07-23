//
//  WhiteboardSlot.swift
//
//  Created by Rene Hexel on 23/7/2022.
//

/// Marker Protocol for a raw representable type (such as an `enum`) that denotes a whiteboard slot
public protocol WhiteboardSlot: RawRepresentable, Sendable where RawValue: BinaryInteger {}

/// Protocol for a type that has a statically-assigned whiteboard slot
public protocol WhiteboardSlotted: Sendable {
    /// Concrete type used for whiteboard slot assignment
    associatedtype Slot: WhiteboardSlot
    /// The whiteboard slot assigned to messages of this type
    static var whiteboardSlot: Slot { get }
}
