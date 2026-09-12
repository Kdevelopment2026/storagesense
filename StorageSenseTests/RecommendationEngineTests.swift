import XCTest
@testable import StorageSense

final class RecommendationEngineTests: XCTestCase {

    func testEmptyLibraryHasNoRecommendation() {
        let result = RecommendationEngine.topRecommendation(from: [])
        XCTAssertNil(result)
    }

    func testRanksByByteCountNotAssetCount() {
        // Fewer, larger videos should outrank many small screenshots.
        let totals: [CategoryTotal] = [
            CategoryTotal(category: .screenshot, assetCount: 500, byteCount: 200_000_000),
            CategoryTotal(category: .video, assetCount: 10, byteCount: 5_000_000_000),
        ]
        let top = RecommendationEngine.topRecommendation(from: totals)
        XCTAssertEqual(top?.category, .video)
    }

    func testZeroCountCategoriesAreExcluded() {
        let totals: [CategoryTotal] = [
            CategoryTotal(category: .selfie, assetCount: 0, byteCount: 0),
            CategoryTotal(category: .largeFile, assetCount: 3, byteCount: 300_000_000),
        ]
        let ranked = RecommendationEngine.rankedRecommendations(from: totals)
        XCTAssertEqual(ranked.count, 1)
        XCTAssertEqual(ranked.first?.category, .largeFile)
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

    func testSingleAssetHeadlineUsesSingularWording() {
        let totals: [CategoryTotal] = [
            CategoryTotal(category: .largeFile, assetCount: 1, byteCount: 60_000_000),
        ]
        let top = RecommendationEngine.topRecommendation(from: totals)
        XCTAssertEqual(top?.headline.contains("1 item,"), true)
    }
}
