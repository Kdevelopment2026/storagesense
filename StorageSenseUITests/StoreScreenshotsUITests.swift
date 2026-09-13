import XCTest

/// Captures the raw frames for the App Store listing against the seeded demo
/// library (48.2 GB, six categories) so the screenshots show a realistic
/// breakdown rather than the Simulator's six sample photos. Frames land in
/// the result bundle as attachments; fastlane/compose_screenshots.py adds
/// the captions and ground.
///
///   xcodebuild -scheme StorageSense -destination '…' test \
///     -only-testing:StorageSenseUITests/StoreScreenshotsUITests -resultBundlePath out.xcresult
final class StoreScreenshotsUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-storagesense-seed-demo", "-storagesense.hasSeenOnboarding", "YES", "-storagesense.appearance", "dark"]
        app.launch()
    }

    func testCaptureStoreFrames() {
        XCTAssertTrue(app.buttons["Re-scan Photos library"].waitForExistence(timeout: 30))
        snap("01-home")

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Videos,'")).firstMatch.tap()
        XCTAssertTrue(app.buttons["Select all"].waitForExistence(timeout: 10))
        // Select the three largest so the running total shows.
        let cells = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Videos item'"))
        for index in 0..<3 where cells.count > index { cells.element(boundBy: index).tap() }
        snap("02-videos")

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Review'")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Not gone forever"].waitForExistence(timeout: 5))
        snap("03-review")
        app.buttons["Keep everything"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Bursts & duplicates,'")).firstMatch.tap()
        XCTAssertTrue(app.buttons["Select all"].waitForExistence(timeout: 10))
        snap("04-bursts")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["Settings"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'iCloud calculator'")).firstMatch.tap()
        let usage = app.textFields["Currently using, in gigabytes"]
        XCTAssertTrue(usage.waitForExistence(timeout: 5))
        usage.tap()
        usage.typeText("187.4")
        app.buttons["Done"].tap()
        snap("05-calculator")
    }

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
