import XCTest
@testable import Whiteboard

private let testWBName = "test-swift-whiteboard"

private enum Slot: Int, WhiteboardSlot {
    case two = 2
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
        let postValue: UInt64 = 0xfeed
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


    /// Test posting and fetching message at index 1
    func testSlotPostGet() {
        let wbd = whiteboard.wbd
        XCTAssertNotNil(wbd)
        guard let wb = wbd.pointee.wb else {
            XCTAssertNotNil(wbd.pointee.wb)
            return
        }
        let postValue: UInt64 = 0xfeed
        let mySlot = Slot.two
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
}
