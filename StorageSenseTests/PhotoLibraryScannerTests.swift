import XCTest
@testable import StorageSense

/// Exercises the pure categorisation and aggregation logic with synthetic
/// inputs — no PhotoKit, no Simulator library.
final class PhotoLibraryScannerTests: XCTestCase {

    private let big = PhotoLibraryScanner.largeFileThresholdBytes

    func testScreenshotWinsRegardlessOfSize() {
        XCTAssertEqual(PhotoLibraryScanner.category(isScreenshot: true, isLivePhoto: true, isVideo: false, isBurst: true, byteCount: big * 3), .screenshot)
    }

    func testLivePhotoOutranksVideoAndBurst() {
        XCTAssertEqual(PhotoLibraryScanner.category(isScreenshot: false, isLivePhoto: true, isVideo: true, isBurst: true, byteCount: 1), .livePhoto)
    }

    func testVideoOutranksBurstAndSize() {
        XCTAssertEqual(PhotoLibraryScanner.category(isScreenshot: false, isLivePhoto: false, isVideo: true, isBurst: true, byteCount: big * 2), .video)
    }

    func testBurstOutranksLargeFile() {
        XCTAssertEqual(PhotoLibraryScanner.category(isScreenshot: false, isLivePhoto: false, isVideo: false, isBurst: true, byteCount: big * 2), .burstDuplicate)
    }

    func testLargeFileThresholdIsInclusive() {
        XCTAssertEqual(PhotoLibraryScanner.category(isScreenshot: false, isLivePhoto: false, isVideo: false, isBurst: false, byteCount: big), .largeFile)
        XCTAssertEqual(PhotoLibraryScanner.category(isScreenshot: false, isLivePhoto: false, isVideo: false, isBurst: false, byteCount: big - 1), .standard)
    }

    func testAggregateSumsPerCategoryAndSkipsEmpty() {
        let assets = [
            AssetSummary(id: "a", category: .video, byteCount: 100, creationDate: nil, burstIdentifier: nil),
            AssetSummary(id: "b", category: .video, byteCount: 50, creationDate: nil, burstIdentifier: nil),
            AssetSummary(id: "c", category: .screenshot, byteCount: 7, creationDate: nil, burstIdentifier: nil),
        ]
        let totals = PhotoLibraryScanner.aggregate(assets)
        XCTAssertEqual(totals.count, 2)
        XCTAssertEqual(totals.first { $0.category == .video }?.byteCount, 150)
        XCTAssertEqual(totals.first { $0.category == .video }?.assetCount, 2)
        XCTAssertEqual(totals.first { $0.category == .screenshot }?.byteCount, 7)
        XCTAssertNil(totals.first { $0.category == .largeFile })
    }

    func testAggregateNeverEmitsSelfie() {
        let assets = [AssetSummary(id: "a", category: .selfie, byteCount: 100, creationDate: nil, burstIdentifier: nil)]
        XCTAssertTrue(PhotoLibraryScanner.aggregate(assets).isEmpty)
    }

    func testAggregateTotalsAlwaysSumToLibraryTotal() {
        let assets = (0..<500).map { i in
            AssetSummary(
                id: "\(i)",
                category: PhotoCategory.v1Cases[i % PhotoCategory.v1Cases.count],
                byteCount: Int64(i * 1_000),
                creationDate: nil,
                burstIdentifier: nil
            )
        }
        let totals = PhotoLibraryScanner.aggregate(assets)
        XCTAssertEqual(totals.reduce(0) { $0 + $1.byteCount }, assets.reduce(0) { $0 + $1.byteCount })
        XCTAssertEqual(totals.reduce(0) { $0 + $1.assetCount }, assets.count)
    }

    func testNearIdenticalStillPhotosBecomeDuplicateCategory() {
        let date = Date(timeIntervalSince1970: 1_000)
        let summaries = [
            AssetSummary(id: "a", category: .standard, byteCount: 100, creationDate: date, burstIdentifier: nil),
            AssetSummary(id: "b", category: .standard, byteCount: 200, creationDate: date.addingTimeInterval(1), burstIdentifier: nil),
            AssetSummary(id: "video", category: .video, byteCount: 300, creationDate: date.addingTimeInterval(1), burstIdentifier: nil),
        ]

        let result = PhotoLibraryScanner.applyDuplicateCategory(to: summaries)

        XCTAssertEqual(result.first?.category, .burstDuplicate)
        XCTAssertEqual(result[1].category, .burstDuplicate)
        XCTAssertEqual(result[2].category, .video)
    }
}
