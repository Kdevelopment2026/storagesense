import XCTest
@testable import StorageSense

/// The calculator is arithmetic on user-entered numbers only (CLAUDE.md,
/// golden rule 4) — these pin that arithmetic and its copy.
final class StorageCalculatorTests: XCTestCase {

    private func tier(_ name: String) -> StorageCalculatorView.Tier {
        StorageCalculatorView.tiers.first { $0.name == name }!
    }

    func testProjectedUsageNeverGoesNegative() {
        XCTAssertEqual(StorageCalculatorView.projectedUsage(current: 10, freeing: 25), 0)
        XCTAssertEqual(StorageCalculatorView.projectedUsage(current: 187.4, freeing: 22.1), 165.3, accuracy: 0.001)
        XCTAssertEqual(StorageCalculatorView.projectedUsage(current: 50, freeing: -5), 50)
    }

    func testCheapestTierPicksFirstThatFits() {
        XCTAssertEqual(StorageCalculatorView.cheapestTier(for: 0)?.name, "5 GB (free)")
        XCTAssertEqual(StorageCalculatorView.cheapestTier(for: 50)?.name, "50 GB")
        XCTAssertEqual(StorageCalculatorView.cheapestTier(for: 50.1)?.name, "200 GB")
        XCTAssertNil(StorageCalculatorView.cheapestTier(for: 13_000))
    }

    func testVerdictWhenDroppingATier() {
        let text = StorageCalculatorView.verdict(projected: 40, current: tier("200 GB"), fits: tier("50 GB"))
        XCTAssertTrue(text.contains("drop to the 50 GB plan"))
    }

    func testVerdictWhenStayingOnSameTier() {
        let text = StorageCalculatorView.verdict(projected: 165.3, current: tier("200 GB"), fits: tier("200 GB"))
        XCTAssertTrue(text.contains("stay on the 200 GB plan"))
        XCTAssertTrue(text.contains("115.3 GB more"))
    }

    func testVerdictWhenStillOverCurrentTier() {
        let text = StorageCalculatorView.verdict(projected: 230, current: tier("200 GB"), fits: tier("2 TB"))
        XCTAssertTrue(text.contains("still over"))
    }

    func testVerdictBeyondLargestTier() {
        let text = StorageCalculatorView.verdict(projected: 13_000, current: tier("12 TB"), fits: nil)
        XCTAssertTrue(text.contains("largest iCloud plan"))
    }
}
