import XCTest
@testable import StorageSense

final class RecommendationEngineTests: XCTestCase {

    func testEmptyLibraryHasNoRecommendation() {
        XCTAssertNil(RecommendationEngine.topRecommendation(from: []))
        XCTAssertTrue(RecommendationEngine.rankedRecommendations(from: []).isEmpty)
    }

    func testRanksByByteCountNotAssetCount() {
        // Fewer, larger videos should outrank many small screenshots.
        let totals: [CategoryTotal] = [
            CategoryTotal(category: .screenshot, assetCount: 500, byteCount: 200_000_000),
            CategoryTotal(category: .video, assetCount: 10, byteCount: 5_000_000_000),
        ]
        XCTAssertEqual(RecommendationEngine.topRecommendation(from: totals)?.category, .video)
    }

    func testZeroCountCategoriesAreExcluded() {
        let totals: [CategoryTotal] = [
            CategoryTotal(category: .screenshot, assetCount: 0, byteCount: 0),
            CategoryTotal(category: .largeFile, assetCount: 3, byteCount: 300_000_000),
        ]
        let ranked = RecommendationEngine.rankedRecommendations(from: totals)
        XCTAssertEqual(ranked.map(\.category), [.largeFile])
    }

    func testSelfieIsNeverRankedInV1() {
        let totals: [CategoryTotal] = [
            CategoryTotal(category: .selfie, assetCount: 900, byteCount: 9_000_000_000),
            CategoryTotal(category: .standard, assetCount: 10, byteCount: 10_000_000),
        ]
        XCTAssertEqual(RecommendationEngine.rankedRecommendations(from: totals).map(\.category), [.standard])
    }

    func testFullOrderingIsDescendingByByteCount() {
        let totals: [CategoryTotal] = [
            CategoryTotal(category: .standard, assetCount: 100, byteCount: 1_000_000),
            CategoryTotal(category: .video, assetCount: 5, byteCount: 3_000_000_000),
            CategoryTotal(category: .livePhoto, assetCount: 200, byteCount: 900_000_000),
            CategoryTotal(category: .burstDuplicate, assetCount: 40, byteCount: 150_000_000),
        ]
        let ranked = RecommendationEngine.rankedRecommendations(from: totals)
        XCTAssertEqual(ranked.map(\.category), [.video, .livePhoto, .burstDuplicate, .standard])
    }

    func testOneDominantCategoryStillListsTheRest() {
        let totals: [CategoryTotal] = [
            CategoryTotal(category: .video, assetCount: 1, byteCount: 100_000_000_000),
            CategoryTotal(category: .screenshot, assetCount: 1, byteCount: 1),
            CategoryTotal(category: .standard, assetCount: 1, byteCount: 1),
        ]
        let ranked = RecommendationEngine.rankedRecommendations(from: totals)
        XCTAssertEqual(ranked.count, 3)
        XCTAssertEqual(ranked.first?.category, .video)
        XCTAssertEqual(RecommendationEngine.share(of: .video, in: totals), 1, accuracy: 0.000_001)
    }

    func testTiesBreakByAssetCountThenDisplayOrder() {
        let byCount: [CategoryTotal] = [
            CategoryTotal(category: .standard, assetCount: 10, byteCount: 500),
            CategoryTotal(category: .screenshot, assetCount: 50, byteCount: 500),
        ]
        XCTAssertEqual(RecommendationEngine.rankedRecommendations(from: byCount).map(\.category), [.screenshot, .standard])

        let fullTie: [CategoryTotal] = [
            CategoryTotal(category: .standard, assetCount: 10, byteCount: 500),
            CategoryTotal(category: .livePhoto, assetCount: 10, byteCount: 500),
        ]
        XCTAssertEqual(RecommendationEngine.rankedRecommendations(from: fullTie).map(\.category), [.livePhoto, .standard])
    }

    func testShareOfLibraryIsZeroForEmptyOrMissing() {
        XCTAssertEqual(RecommendationEngine.share(of: .video, in: []), 0)
        let totals = [CategoryTotal(category: .video, assetCount: 1, byteCount: 10)]
        XCTAssertEqual(RecommendationEngine.share(of: .screenshot, in: totals), 0)
    }

    func testSingleAssetHeadlineUsesSingularWording() {
        let totals = [CategoryTotal(category: .largeFile, assetCount: 1, byteCount: 60_000_000)]
        XCTAssertEqual(RecommendationEngine.topRecommendation(from: totals)?.headline.contains("1 item,"), true)
    }

    func testSpokenByteFormatExpandsUnits() {
        XCTAssertTrue(ByteFormatter.spoken(1_200_000_000).contains("gigabytes"))
        XCTAssertTrue(ByteFormatter.spoken(48_000_000).contains("megabytes"))
    }
}
