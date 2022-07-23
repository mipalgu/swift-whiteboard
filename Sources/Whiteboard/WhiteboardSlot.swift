//
//  WhiteboardSlot.swift
//
//  Created by Rene Hexel on 23/7/2022.
//

/// Marker Protocol for a raw representable type (such as an `enum`) that denotes a whiteboard slot
public protocol WhiteboardSlot: RawRepresentable, Sendable where RawValue: BinaryInteger {}
