import XCTest
@testable import Whiteboard

private let testWBName = "test-swift-whiteboard"

private enum ExampleWhiteboardSlot: Int, WhiteboardSlot {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
}

private struct ExampleMessage: WhiteboardSlotted, Sendable, Equatable {
    static let whiteboardSlot = ExampleWhiteboardSlot.three
    let value: Int32
}

private struct PerformanceMessage: WhiteboardSlotted, Sendable, Equatable {
    static let whiteboardSlot = ExampleWhiteboardSlot.four
    let value: UInt32
}

final class WhiteboardTests: XCTestCase {
    let whiteboard = Whiteboard(name: testWBName)

    /// Test whiteboard invariants
    func testWB() {
        let wbd = whiteboard.wbd
        XCTAssertNotNil(wbd)
        guard let wb = wbd.pointee.wb else {
            XCTAssertNotNil(wbd.pointee.wb)
            return
        }
        XCTAssertEqual(wb.pointee.magic, 0xfeeda11deadbeef6)
        XCTAssertEqual(wb.pointee.version, 2207)
        XCTAssertNotEqual(wbd.pointee.fd, 0)
        XCTAssertEqual(wb.pointee.indexes.0, 0)
        XCTAssertEqual(wb.pointee.event_counters.0, 0)
    }

    /// Test posting and fetching message at index 1
    func testLowLevelPostGet() {
        let wbd = whiteboard.wbd
        XCTAssertNotNil(wbd)
        guard let wb = wbd.pointee.wb else {
            XCTAssertNotNil(wbd.pointee.wb)
            return
        }
        let postValue: UInt64 = UInt64.random(in: UInt64.min...UInt64.max)
        let i = wb.pointee.indexes.1
        let e = wb.pointee.event_counters.1
        guard let next: UnsafeMutablePointer<UInt64> = whiteboard.nextMessagePointer(forSlotAtIndex: 1) else {
            XCTFail() ; return
        }
        next.pointee = postValue
        whiteboard.incrementGeneration(forSlotAtIndex: 1)
        whiteboard.incrementEventCounter(forSlotAtIndex: 1)
        guard let current: UnsafeMutablePointer<UInt64> = whiteboard.currentMessagePointer(forSlotAtIndex: 1) else {
            XCTFail() ; return
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
        let postValue: UInt64 = UInt64.random(in: UInt64.min...UInt64.max)
        let mySlot = ExampleWhiteboardSlot.two
        let i = wb.pointee.indexes.2
        let e = wb.pointee.event_counters.2
        guard let next: UnsafeMutablePointer<UInt64> = whiteboard.nextMessagePointer(for: mySlot) else {
            XCTFail() ; return
        }
        next.pointee = postValue
        whiteboard.incrementGeneration(for: mySlot)
        whiteboard.incrementEventCounter(for: mySlot)
        guard let current: UnsafeMutablePointer<UInt64> = whiteboard.currentMessagePointer(for: mySlot) else {
            XCTFail() ; return
        }
        XCTAssertEqual(current, next)
        XCTAssertEqual(current.pointee, postValue)
        XCTAssertTrue(wb.pointee.indexes.2 == i + 1 || wb.pointee.indexes.2 == 0 && wb.pointee.indexes.2 != i)
        XCTAssertEqual(wb.pointee.event_counters.2, e &+ 1)
    }

    /// Test posting and fetching statically typed messagges
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
            XCTFail() ; return
        }
        guard let next: UnsafeMutablePointer<ExampleMessage> = whiteboard.nextMessagePointer() else {
            XCTFail() ; return
        }
        XCTAssertEqual(nextWithSlot, next)
        let postedValue = ExampleMessage(value: Int32.random(in: Int32.min...Int32.max))
        whiteboard.post(message: postedValue)
        let receivedValue: ExampleMessage = whiteboard.getMessage()
        guard let current: UnsafeMutablePointer<ExampleMessage> = whiteboard.currentMessagePointer() else {
            XCTFail() ; return
        }
        XCTAssertEqual(current, next)
        XCTAssertEqual(current.pointee, receivedValue)
        XCTAssertEqual(current.pointee, postedValue)
        XCTAssertTrue(wb.pointee.indexes.3 == i + 1 || wb.pointee.indexes.3 == 0 && wb.pointee.indexes.3 != i)
        XCTAssertEqual(wb.pointee.event_counters.3, e &+ 1)
    }

    func testPostPerformance() {
        let message = PerformanceMessage(value: UInt32.random(in: UInt32.min...UInt32.max))
        measure {
            for _ in 0..<100_000 {
                whiteboard.post(message: message)
            }
        }
    }

    func testGetPerformance() {
        measure {
            for _ in 0..<100_000 {
                let _: PerformanceMessage = whiteboard.getMessage()
            }
        }
    }
}
