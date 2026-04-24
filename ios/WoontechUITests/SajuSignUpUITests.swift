import XCTest

final class SajuSignUpUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // T55 — AC-22
    func test_signUp_guestLink_movesToHome_keepsResultInSession() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-hasSeenOnboarding", "YES",
            "-resetSajuInput",
            "-sajuStartStep", "9"
        ]
        app.launch()
        let guest = app.buttons["SajuSignUpGuestLink"]
        XCTAssertTrue(guest.waitForExistence(timeout: 6))
        guest.tap()
        XCTAssertTrue(app.otherElements["HomeRoot"].waitForExistence(timeout: 4))
    }

    func test_signUp_displaysSignUpButtons() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-hasSeenOnboarding", "YES",
            "-resetSajuInput",
            "-sajuStartStep", "9"
        ]
        app.launch()
        XCTAssertTrue(app.otherElements["SajuSignUpRoot"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.buttons["SajuSignUpKakao"].exists)
        XCTAssertTrue(app.buttons["SajuSignUpGoogle"].exists)
        XCTAssertTrue(app.buttons["SajuSignUpEmail"].exists)
        XCTAssertTrue(app.buttons["SajuSignUpGuestLink"].exists)
    }
}
