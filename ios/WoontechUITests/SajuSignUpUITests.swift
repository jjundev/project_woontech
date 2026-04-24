import XCTest

final class SajuSignUpUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // T55 — AC-22
    func test_signUp_laterLink_movesToHome_keepsResultInSession() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-hasSeenOnboarding", "YES",
            "-resetSajuInput",
            "-sajuStartStep", "9"
        ]
        app.launch()
        let later = app.buttons["SajuSignUpLaterLink"]
        XCTAssertTrue(later.waitForExistence(timeout: 6))
        later.tap()
        XCTAssertTrue(app.otherElements["HomeRoot"].waitForExistence(timeout: 4))
    }

    func test_signUp_displaysThreeSignUpButtons_andLegalLinks() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-hasSeenOnboarding", "YES",
            "-resetSajuInput",
            "-sajuStartStep", "9"
        ]
        app.launch()
        XCTAssertTrue(app.otherElements["SajuSignUpRoot"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.buttons["SajuSignUpApple"].exists)
        XCTAssertTrue(app.buttons["SajuSignUpGoogle"].exists)
        XCTAssertTrue(app.buttons["SajuSignUpEmail"].exists)
        XCTAssertTrue(app.buttons["SajuSignUpTermsLink"].exists)
        XCTAssertTrue(app.buttons["SajuSignUpPrivacyLink"].exists)
    }
}
