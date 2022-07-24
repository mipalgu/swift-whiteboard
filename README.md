# swift-whiteboard

A Swift shared-memory implementation of the blackboard communication architecture.

## Overview

This is a Swift wrapper around [gusimplewhiteboard](https://github.com/mipalgu/gusimplewhiteboard).
This package wraps the high-speed, concurrency-safe gusimplewhiteboard C library for use in Swift. The package provides a sendable ``Whiteboard`` class that allows concurrent read and write access to a common message base. Message slots can be configured by conforming to the ``WhiteboardSlot`` protocol. You can create your own type-safe messages through conformance to the ``WhiteboardSlotted`` protocol.

## Prerequisites

### Swift 5.6 or higher

To build, download Swift from https://swift.org/download/ -- if you are using macOS, make sure you have the command line tools installed as well).  Test that your compiler works using `swift --version`, which should give you something like

	$ swift --version
	swift-driver version: 1.45.2 Apple Swift version 5.6 (swiftlang-5.6.0.323.62 clang-1316.0.20.8)
    Target: x86_64-apple-darwin20.3.0

on macOS, or on Linux you should get something like:

	$ swift --version
	Swift version 5.6.2 (swift-5.6.2-RELEASE)
	Target: x86_64-unknown-linux-gnu

## Usage

### Embedding this Package

Typically, you need to embed this package into your own project using the [Swift Package Manager](https://swift.org/package-manager/).  After installing the prerequisites, add this package as a dependency to your `Package.swift` file, e.g.:

```swift
// swift-tools-version:5.6

import PackageDescription

let package = Package(name: "MyPackage",
    dependencies: [
        .package(url: "https://github.com/mipalgu/swift-whiteboard.git", branch: "main"),
    ],    
    targets: [
        .target(name: "MyPackage",
                dependencies: [
                    .product(name: "Whiteboard", package: "swift-whiteboard")
                ]
        )
    ]
)
```

### Using the Whiteboard

For details on how to use the whiteboard, see the [documentation](https://github.com/mipalgu/swift-whiteboard/blob/main/Sources/Whiteboard/Whiteboard.docc/Whiteboard.md).  For a quick start, have a look at the [Getting Started](https://github.com/mipalgu/swift-whiteboard/blob/main/Sources/Whiteboard/Whiteboard.docc/GettingStarted.md) document.