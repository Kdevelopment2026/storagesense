import XCTest

/// Walks every v1 screen by its accessibility labels — so a missing label
/// fails the test — and attaches a screenshot of each for visual review.
/// Run: xcodebuild -scheme StorageSense -destination '…' test -only-testing:StorageSenseUITests
final class ScreenWalkthroughUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-storagesense.hasSeenOnboarding", "YES"]
        app.launch()
    }

    func testWalkEveryScreen() {
        // Permission screen (first run on a fresh Simulator) or Home.
        let continueButton = app.buttons["Continue"]
        if continueButton.waitForExistence(timeout: 3) {
            snap("permission")
            continueButton.tap()
            // The Photos prompt is owned by SpringBoard, not the app.
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let allow = springboard.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Allow'")).firstMatch
            if allow.waitForExistence(timeout: 10) {
                snap("system-prompt")
                allow.tap()
            }
        }

        XCTAssertTrue(app.staticTexts["Your Photos library"].waitForExistence(timeout: 20), "Home never appeared")
        // Wait for the scan to finish (Re-scan only shows once there's a result).
        XCTAssertTrue(app.buttons["Re-scan Photos library"].waitForExistence(timeout: 60), "Scan never completed")
        snap("home")

        // Category detail via the first chip (chips are labelled "<Category>, N items, size").
        let chip = app.buttons.matching(NSPredicate(format: "label CONTAINS 'items,'")).firstMatch
        XCTAssertTrue(chip.waitForExistence(timeout: 5), "No category chip found")
        chip.tap()
        let selectAll = app.buttons["Select all"]
        XCTAssertTrue(selectAll.waitForExistence(timeout: 10), "Category detail never loaded")
        snap("category-detail")

        // Select everything, open Review, then keep everything.
        selectAll.tap()
        let review = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Review'")).firstMatch
        XCTAssertTrue(review.waitForExistence(timeout: 5))
        snap("category-detail-selected")
        review.tap()
        XCTAssertTrue(app.staticTexts["Not gone forever"].waitForExistence(timeout: 5), "Review sheet missing Recently Deleted copy")
        snap("review-delete")
        app.buttons["Keep everything"].tap()

        // Back to Home, into Settings, then the calculator.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Data Not Collected"].waitForExistence(timeout: 5))
        snap("settings")
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'iCloud calculator'")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'what you type in'")).firstMatch.waitForExistence(timeout: 5), "Manual-entry disclaimer missing")
        snap("calculator")
    }

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
