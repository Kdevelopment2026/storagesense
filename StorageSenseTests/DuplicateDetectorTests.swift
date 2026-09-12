import XCTest
@testable import StorageSense

final class DuplicateDetectorTests: XCTestCase {

    private func asset(_ id: String, secondsFromNow: TimeInterval, burst: String? = nil) -> AssetSummary {
        AssetSummary(id: id, category: .burstDuplicate, byteCount: 1, creationDate: Date(timeIntervalSince1970: 1_000 + secondsFromNow), burstIdentifier: burst)
    }

    func testBurstIdentifierGroupsTogether() {
        let groups = DuplicateDetector.groups(in: [
            asset("a", secondsFromNow: 0, burst: "x"),
            asset("b", secondsFromNow: 500, burst: "x"),
            asset("c", secondsFromNow: 900, burst: "y"),
        ])
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(Set(groups[0].assets.map(\.id)), ["a", "b"])
    }

    func testProximityGroupsRapidRepeats() {
        let groups = DuplicateDetector.groups(in: [
            asset("a", secondsFromNow: 0),
            asset("b", secondsFromNow: 1.5),
            asset("c", secondsFromNow: 3.0),
            asset("d", secondsFromNow: 60),
        ])
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(Set(groups[0].assets.map(\.id)), ["a", "b", "c"])
    }

    func testSingletonsAreNotDuplicates() {
        XCTAssertTrue(DuplicateDetector.groups(in: [asset("a", secondsFromNow: 0, burst: "solo")]).isEmpty)
        XCTAssertTrue(DuplicateDetector.groups(in: [asset("a", secondsFromNow: 0), asset("b", secondsFromNow: 30)]).isEmpty)
    }

    func testAssetsWithoutDatesAreIgnoredByProximity() {
        let undated = AssetSummary(id: "u", category: .burstDuplicate, byteCount: 1, creationDate: nil, burstIdentifier: nil)
        XCTAssertTrue(DuplicateDetector.groups(in: [undated, undated]).isEmpty)
    }
}
