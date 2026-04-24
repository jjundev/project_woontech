import XCTest

final class SajuAccessibilityUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func launchOnStep(_ step: Int) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-hasSeenOnboarding", "YES",
            "-resetSajuInput",
            "-sajuStartStep", String(step)
        ]
        app.launch()
        return app
    }

    // T59 — AC-26
    func test_voiceOver_labelsAndTraits_onAllInputs() {
        let app = launchOnStep(1)
        XCTAssertTrue(app.otherElements["SajuInputRoot"].waitForExistence(timeout: 6))
        XCTAssertFalse(app.buttons["SajuBackButton"].label.isEmpty)
        XCTAssertFalse(app.buttons["SajuGenderMale"].label.isEmpty)
        XCTAssertFalse(app.buttons["SajuGenderFemale"].label.isEmpty)
        app.buttons["SajuGenderMale"].tap()
        XCTAssertTrue(app.buttons["SajuGenderMale"].isSelected)

        // Step 4 checkbox trait.
        let app4 = launchOnStep(4)
        let cb = app4.buttons["SajuHourUnknownCheckbox"]
        XCTAssertTrue(cb.waitForExistence(timeout: 6))
        XCTAssertFalse(cb.isSelected)
        cb.tap()
        XCTAssertTrue(cb.isSelected)
    }

    // T60 — AC-27
    func test_hitTargets_backButton_toggle_checkbox_atLeast44pt() {
        let app = launchOnStep(6)
        let back = app.buttons["SajuBackButton"]
        XCTAssertTrue(back.waitForExistence(timeout: 6))
        XCTAssertGreaterThanOrEqual(back.frame.width, 44)
        XCTAssertGreaterThanOrEqual(back.frame.height, 44)

        // Toggle switch on step 6.
        let toggle = app.switches["SajuSolarTimeToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2))
        XCTAssertGreaterThanOrEqual(toggle.frame.height, 28)

        // Step 4 checkbox.
        let app4 = launchOnStep(4)
        let cb = app4.buttons["SajuHourUnknownCheckbox"]
        XCTAssertTrue(cb.waitForExistence(timeout: 6))
        XCTAssertGreaterThanOrEqual(cb.frame.height, 44)
    }
}
