import cwhiteboard
@testable import Whiteboard
import XCTest

private let testWBName = "test-swift-whiteboard"

private enum ExampleWhiteboardSlot: Int, WhiteboardSlot {
    case zero
    case one
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
}

private struct ExampleMessage: WhiteboardSlotted, Equatable {
    static let whiteboardSlot = ExampleWhiteboardSlot.three
    let value: Int32
}

private struct PerformanceMessage: WhiteboardSlotted, Equatable {
    static let whiteboardSlot = ExampleWhiteboardSlot.four
    let value: UInt32
}

final class WhiteboardTests: XCTestCase {
    let whiteboard = Whiteboard(name: testWBName)

    override func setUp() {
        XCTAssertEqual(0, unsetenv(GSW_DEFAULT_ENV))
    }

    override func tearDown() {
        if let wb = whiteboard.wbd.pointee.wb {
            withUnsafeMutablePointer(to: &wb.pointee.indexes.0) { start in
                let buffer = UnsafeMutableBufferPointer(start: start, count: Int(GSW_TOTAL_MESSAGE_TYPES))
                buffer.indices.forEach { buffer[$0] = 0 }
            }
            withUnsafeMutablePointer(to: &wb.pointee.event_counters.0) { start in
                let buffer = UnsafeMutableBufferPointer(start: start, count: Int(GSW_TOTAL_MESSAGE_TYPES))
                buffer.indices.forEach { buffer[$0] = 0 }
            }
        }
    }

    /// Test whiteboard invariants
    func testWB() {
        let wbd = whiteboard.wbd
        XCTAssertNotNil(wbd)
        guard let wb = wbd.pointee.wb else {
            XCTAssertNotNil(wbd.pointee.wb)
            return
        }
        XCTAssertEqual(Whiteboard.slotCount, Int(GSW_TOTAL_MESSAGE_TYPES))
        XCTAssertEqual(whiteboard.version, Whiteboard.version)
        XCTAssertEqual(Int(wb.pointee.version), Whiteboard.version)
        XCTAssertEqual(Int(wb.pointee.eventcount), whiteboard.eventCount)
        XCTAssertEqual(wb.pointee.magic, 0xfeeda11deadbeef6)
        XCTAssertNotEqual(wbd.pointee.fd, 0)
        XCTAssertEqual(wb.pointee.indexes.0, 0)
        XCTAssertEqual(wb.pointee.event_counters.0, 0)
    }

    /// Tests whether the init sets up a whiteboard with the global name.
    func testEmptyInit() {
        let whiteboard = Whiteboard()
        let whiteboard2 = Whiteboard(name: GSW_DEFAULT_NAME)
        let slot = ExampleWhiteboardSlot.zero
        whiteboard.post(message: UInt64.min, to: slot)
        let result1: UInt64 = whiteboard2.getMessage(from: slot)
        XCTAssertEqual(UInt64.min, result1)
        let value = UInt64.random(in: (UInt64.min + 1)...UInt64.max)
        whiteboard.post(message: value, to: slot)
        let result2: UInt64 = whiteboard2.getMessage(from: slot)
        XCTAssertEqual(value, result2)
    }

    /// Tests whether the init sets up a whiteboard with the name that exists
    /// in the environment.
    func testEmptyInitFromEnvironment() {
        let name = "test_env_name"
        XCTAssertEqual(0, setenv(GSW_DEFAULT_ENV, name, 1))
        let whiteboard = Whiteboard()
        let whiteboard2 = Whiteboard(name: name)
        let slot = ExampleWhiteboardSlot.zero
        whiteboard.post(message: UInt64.min, to: slot)
        let result1: UInt64 = whiteboard2.getMessage(from: slot)
        XCTAssertEqual(UInt64.min, result1)
        let value = UInt64.random(in: (UInt64.min + 1)...UInt64.max)
        whiteboard.post(message: value, to: slot)
        let result2: UInt64 = whiteboard2.getMessage(from: slot)
        XCTAssertEqual(value, result2)
    }

    /// Tests whether it is possible to post/get messages that are referenced
    /// from pointers.
    func testPointerPostGet() {
        let value1 = UInt64.min
        let value2 = UInt64.random(in: (UInt64.min + 1)...UInt64.max)
        let slot = ExampleWhiteboardSlot.zero
        withUnsafePointer(to: value1) { p in
            whiteboard.post(messageReferencedBy: p, to: slot)
        }
        XCTAssertEqual(value1, whiteboard.getMessage(from: slot))
        withUnsafePointer(to: value2) { p in
            whiteboard.post(messageReferencedBy: p, to: slot)
        }
        XCTAssertEqual(value2, whiteboard.getMessage(from: slot))
    }

    /// Tests whether it is possible to post/get messages that are referenced
    /// from pointers using the `fromSlotAtIndex` variants of post/get.
    func testLowLevelPointerPostGet() {
        let value1 = UInt64.min
        let value2 = UInt64.random(in: (UInt64.min + 1)...UInt64.max)
        let slot = CInt(ExampleWhiteboardSlot.zero.rawValue)
        withUnsafePointer(to: value1) { p in
            whiteboard.post(messageReferencedBy: p, toSlotAtIndex: slot)
        }
        XCTAssertEqual(value1, whiteboard.getMessage(fromSlotAtIndex: slot))
        withUnsafePointer(to: value2) { p in
            whiteboard.post(messageReferencedBy: p, toSlotAtIndex: slot)
        }
        XCTAssertEqual(value2, whiteboard.getMessage(fromSlotAtIndex: slot))
    }

    /// Test posting and fetching message at index 1
    func testLowLevelPostGet() {
        let wbd = whiteboard.wbd
        XCTAssertNotNil(wbd)
        guard let wb = wbd.pointee.wb else {
            XCTAssertNotNil(wbd.pointee.wb)
            return
        }
        let postValue = UInt64.random(in: UInt64.min...UInt64.max)
        let i = wb.pointee.indexes.1
        let e = wb.pointee.event_counters.1
        guard let next: UnsafeMutablePointer<UInt64> = whiteboard.nextMessagePointer(forSlotAtIndex: 1) else {
            XCTFail("`nextMessagePoint(forSlotAtIndex:) returned nil`") ; return
        }
        next.pointee = postValue
        whiteboard.incrementGeneration(forSlotAtIndex: 1)
        whiteboard.incrementEventCounter(forSlotAtIndex: 1)
        guard let current: UnsafeMutablePointer<UInt64> = whiteboard.currentMessagePointer(forSlotAtIndex: 1) else {
            XCTFail("`currentMessagePoint(forSlotAtIndex:)` returned nil") ; return
        }
        XCTAssertEqual(current, next)
        XCTAssertEqual(current.pointee, postValue)
        XCTAssertTrue(wb.pointee.indexes.1 == i + 1 || wb.pointee.indexes.1 == 0 && wb.pointee.indexes.1 != i)
        XCTAssertEqual(wb.pointee.event_counters.1, e &+ 1)
    }

    /// Test posting and fetching message at ExampleWhiteboardSlot.two
    func testSlotPostGet() {
        let wbd = whiteboard.wbd
        XCTAssertNotNil(wbd)
        guard let wb = wbd.pointee.wb else {
            XCTAssertNotNil(wbd.pointee.wb)
            return
        }
        let postValue = UInt64.random(in: UInt64.min...UInt64.max)
        let mySlot = ExampleWhiteboardSlot.two
        let i = wb.pointee.indexes.2
        let e = wb.pointee.event_counters.2
        guard let next: UnsafeMutablePointer<UInt64> = whiteboard.nextMessagePointer(for: mySlot) else {
            XCTFail("`nextMessagePointer(for:)` returned nil") ; return
        }
        next.pointee = postValue
        whiteboard.incrementGeneration(for: mySlot)
        whiteboard.incrementEventCounter(for: mySlot)
        guard let current: UnsafeMutablePointer<UInt64> = whiteboard.currentMessagePointer(for: mySlot) else {
            XCTFail("`currentMessagePointer(for:)` returned nil") ; return
        }
        XCTAssertEqual(current, next)
        XCTAssertEqual(current.pointee, postValue)
        XCTAssertTrue(wb.pointee.indexes.2 == i + 1 || wb.pointee.indexes.2 == 0 && wb.pointee.indexes.2 != i)
        XCTAssertEqual(wb.pointee.event_counters.2, e &+ 1)
    }

    /// Test posting and fetching statically typed messagges
    func testTypedPointerPostGet() {
        let wbd = whiteboard.wbd
        XCTAssertNotNil(wbd)
        guard let wb = wbd.pointee.wb else {
            XCTAssertNotNil(wbd.pointee.wb)
            return
        }
        let mySlot = ExampleWhiteboardSlot.three
        let i = wb.pointee.indexes.3
        let e = wb.pointee.event_counters.3
        guard let nextWithSlot: UnsafeMutablePointer<ExampleMessage> = whiteboard.nextMessagePointer(for: mySlot) else {
            XCTFail("`nextMessagePointer(for:)` returned nil") ; return
        }
        guard let next: UnsafeMutablePointer<ExampleMessage> = whiteboard.nextMessagePointer() else {
            XCTFail("`nextMessagePointer()` returned nil") ; return
        }
        XCTAssertEqual(nextWithSlot, next)
        let postedValue = ExampleMessage(value: Int32.random(in: Int32.min...Int32.max))
        withUnsafePointer(to: postedValue) { p in
            whiteboard.post(messageReferencedBy: p)
        }
        let receivedValue: ExampleMessage = whiteboard.getMessage()
        guard let current: UnsafeMutablePointer<ExampleMessage> = whiteboard.currentMessagePointer() else {
            XCTFail("`currentMessagePointer()` returned nil") ; return
        }
        XCTAssertEqual(current, next)
        XCTAssertEqual(current.pointee, receivedValue)
        XCTAssertEqual(current.pointee, postedValue)
        XCTAssertTrue(wb.pointee.indexes.3 == i + 1 || wb.pointee.indexes.3 == 0 && wb.pointee.indexes.3 != i)
        XCTAssertEqual(wb.pointee.event_counters.3, e &+ 1)
    }

    /// Test posting and fetching statically typed messages
    func testTypedPostGet() {
        let wbd = whiteboard.wbd
        XCTAssertNotNil(wbd)
        guard let wb = wbd.pointee.wb else {
            XCTAssertNotNil(wbd.pointee.wb)
            return
        }
        let mySlot = ExampleWhiteboardSlot.three
        let i = wb.pointee.indexes.3
        let e = wb.pointee.event_counters.3
        guard let nextWithSlot: UnsafeMutablePointer<ExampleMessage> = whiteboard.nextMessagePointer(for: mySlot) else {
            XCTFail("`nextMessagePointer(for:)` returned nil") ; return
        }
        guard let next: UnsafeMutablePointer<ExampleMessage> = whiteboard.nextMessagePointer() else {
            XCTFail("`nextMessagePointer()` returned nil") ; return
        }
        XCTAssertEqual(nextWithSlot, next)
        let postedValue = ExampleMessage(value: Int32.random(in: Int32.min...Int32.max))
        whiteboard.post(message: postedValue)
        let receivedValue: ExampleMessage = whiteboard.getMessage()
        guard let current: UnsafeMutablePointer<ExampleMessage> = whiteboard.currentMessagePointer() else {
            XCTFail("`currentMessagePointer()` returned nil") ; return
        }
        XCTAssertEqual(current, next)
        XCTAssertEqual(current.pointee, receivedValue)
        XCTAssertEqual(current.pointee, postedValue)
        XCTAssertTrue(wb.pointee.indexes.3 == i + 1 || wb.pointee.indexes.3 == 0 && wb.pointee.indexes.3 != i)
        XCTAssertEqual(wb.pointee.event_counters.3, e &+ 1)
    }

    func testArray() {
        let a = [1, 2, 3, 4]
        whiteboard.post(array: a, to: ExampleWhiteboardSlot.five)
        let b: [Int] = whiteboard.getArray(from: ExampleWhiteboardSlot.five)
        XCTAssertEqual(a, b)
    }

    /// Test posting performance
    func testPostPerformance() {
        let message = PerformanceMessage(value: UInt32.random(in: UInt32.min...UInt32.max))
        // swiftlint:disable:next no_space_in_method_call
        measure {
            for _ in 0..<100_000 {
                whiteboard.post(message: message)
            }
        }
    }

    /// Test array posting performance
    func testArrayPostPerformance() {
        let a = Array<Int>(repeating: Int.random(in: Int.min...Int.max), count: (Int(GU_SIMPLE_WHITEBOARD_BUFSIZE) - MemoryLayout<UInt16>.stride) / MemoryLayout<Int>.stride)
        // swiftlint:disable:next no_space_in_method_call
        measure {
            for _ in 0..<100_000 {
                whiteboard.post(array: a, to: ExampleWhiteboardSlot.seven)
            }
        }
    }

    /// Test receiving performance
    func testGetPerformance() {
        // swiftlint:disable:next no_space_in_method_call
        measure {
            for _ in 0..<100_000 {
                let _: PerformanceMessage = whiteboard.getMessage()
            }
        }
    }

    /// Test array posting performance
    func testArrayPostGetPerformance() {
        let a = Array<Int>(repeating: Int.random(in: Int.min...Int.max), count: (Int(GU_SIMPLE_WHITEBOARD_BUFSIZE) - MemoryLayout<UInt16>.stride) / MemoryLayout<Int>.stride)
        // swiftlint:disable:next no_space_in_method_call
        measure {
            for _ in 0..<100_000 {
                whiteboard.post(array: a, to: ExampleWhiteboardSlot.eight)
                let _: [Int] = whiteboard.getArray(from: ExampleWhiteboardSlot.eight)
            }
        }
    }
}
