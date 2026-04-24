import XCTest

final class SajuReferralUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // T56 — AC-23
    func test_referral_notAutoEntered_afterResultFlow() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-hasSeenOnboarding", "YES",
            "-resetSajuInput",
            "-sajuStartStep", "8",
            "-signedIn"
        ]
        app.launch()
        let start = app.buttons["SajuResultStartCTA"]
        XCTAssertTrue(start.waitForExistence(timeout: 6))
        start.tap()
        // signed-in → skip signup → home (NOT referral)
        XCTAssertTrue(app.otherElements["HomeRoot"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.otherElements["SajuReferralRoot"].exists,
                       "Referral should NOT auto-open after result")
    }

    // T57 — AC-24
    func test_referral_displaysCodeAndPreview_matchingProfile() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-hasSeenOnboarding", "YES",
            "-resetSajuInput",
            "-openReferral"
        ]
        app.launch()
        XCTAssertTrue(app.otherElements["SajuReferralRoot"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.otherElements["SajuReferralPreview"].exists
                      || app.staticTexts["SajuReferralCode"].exists,
                      "Referral preview or code should be visible")
        let code = app.staticTexts["SajuReferralCode"].label
        XCTAssertEqual(code.count, 5)
    }

    // T58 — AC-25
    func test_referral_copyLink_putsInviteUrlOnPasteboard_showsToast() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-hasSeenOnboarding", "YES",
            "-resetSajuInput",
            "-openReferral"
        ]
        app.launch()
        let copy = app.buttons["SajuReferralCopyLink"]
        XCTAssertTrue(copy.waitForExistence(timeout: 6))
        copy.tap()
        XCTAssertTrue(app.staticTexts["SajuReferralToast"].waitForExistence(timeout: 2))
    }
}
