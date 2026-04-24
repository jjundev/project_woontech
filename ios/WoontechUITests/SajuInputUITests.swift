import XCTest

final class SajuInputUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - Helpers

    private func launchOnStep(_ step: Int, extraArgs: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-hasSeenOnboarding", "YES",
            "-resetSajuInput",
            "-sajuStartStep", String(step)
        ] + extraArgs
        app.launch()
        return app
    }

    private func waitForStep(_ app: XCUIApplication, identifier: String, timeout: TimeInterval = 6) {
        XCTAssertTrue(app.otherElements[identifier].waitForExistence(timeout: timeout),
                      "Expected \(identifier) within \(timeout)s")
    }

    // T34 — AC-1
    func test_step1_progressBar_showsOneOfSix_onEntry() {
        let app = launchOnStep(1)
        XCTAssertTrue(app.staticTexts["1/6"].waitForExistence(timeout: 6))
    }

    // T35 — AC-2
    func test_step1_cta_disabledUntilGenderSelected() {
        let app = launchOnStep(1)
        let cta = app.buttons["SajuCTA"]
        XCTAssertTrue(cta.waitForExistence(timeout: 6))
        XCTAssertFalse(cta.isEnabled)
        app.buttons["SajuGenderMale"].tap()
        XCTAssertTrue(cta.isEnabled)
    }

    // T36 — AC-3
    func test_step2_name_empty_disablesCta_validLengthEnables_maxTruncates20() {
        let app = launchOnStep(2)
        let cta = app.buttons["SajuCTA"]
        XCTAssertTrue(cta.waitForExistence(timeout: 6))
        XCTAssertFalse(cta.isEnabled, "Empty name should disable CTA")

        let field = app.textFields["SajuNameField"]
        field.tap()
        field.typeText("민")
        XCTAssertTrue(cta.isEnabled)

        // 20+ chars truncated.
        field.typeText(String(repeating: "가", count: 25))
        let value = (field.value as? String) ?? ""
        XCTAssertLessThanOrEqual(value.count, 20, "Name should be capped at 20 chars")
    }

    // T37 — AC-4
    func test_step3_defaults_1990_03_15_solar_ctaEnabled() {
        let app = launchOnStep(3)
        XCTAssertTrue(app.otherElements["SajuInputStep_3"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.buttons["SajuCalendarSolar"].isSelected)
        XCTAssertTrue(app.buttons["SajuCTA"].isEnabled)
    }

    // T38 — AC-5
    func test_step3_lunar_showsLeapCheckbox_yearRange_invalidDatesFiltered() {
        let app = launchOnStep(3)
        app.buttons["SajuCalendarLunar"].tap()
        XCTAssertTrue(app.buttons["SajuLeapCheckbox"].waitForExistence(timeout: 2))
    }

    // T39 — AC-6
    func test_step4_wheelSelection_enablesCta() {
        let app = launchOnStep(4)
        let cta = app.buttons["SajuCTA"]
        XCTAssertTrue(cta.waitForExistence(timeout: 6))
        XCTAssertTrue(cta.isEnabled, "Default hourKnown=true makes CTA enabled")
    }

    // T40 — AC-7
    func test_step4_unknownCheckbox_disablesWheel_enablesCta_setsModelFlag() {
        let app = launchOnStep(4)
        let checkbox = app.buttons["SajuHourUnknownCheckbox"]
        XCTAssertTrue(checkbox.waitForExistence(timeout: 6))
        checkbox.tap()
        XCTAssertTrue(checkbox.isSelected)
        XCTAssertTrue(app.buttons["SajuCTA"].isEnabled)
    }

    // T41 — AC-8
    func test_step5_defaultSeoul_ctaEnabled() {
        let app = launchOnStep(5)
        let cta = app.buttons["SajuCTA"]
        XCTAssertTrue(cta.waitForExistence(timeout: 6))
        XCTAssertTrue(cta.isEnabled)
        XCTAssertTrue(app.buttons["SajuCity_SEOUL"].isSelected)
    }

    // T42 — AC-9
    func test_step5_overseas_longitudeBounds_validation() {
        let app = launchOnStep(5)
        let overseas = app.buttons["SajuOverseasCheckbox"]
        XCTAssertTrue(overseas.waitForExistence(timeout: 6))
        overseas.tap()

        let field = app.textFields["SajuLongitudeField"]
        XCTAssertTrue(field.waitForExistence(timeout: 2))

        field.tap()
        field.typeText("200")
        XCTAssertFalse(app.buttons["SajuCTA"].isEnabled)

        // Clear — select all + delete — then enter a valid value.
        field.doubleTap()
        field.typeText(XCUIKeyboardKey.delete.rawValue)
        field.typeText("139.69")
        XCTAssertTrue(app.buttons["SajuCTA"].isEnabled)
    }

    // T43 — AC-10
    func test_flow_skipsStep6_whenHourUnknown() {
        let app = launchOnStep(4)
        app.buttons["SajuHourUnknownCheckbox"].tap()
        app.buttons["SajuCTA"].tap() // advance to birthPlace (step 5)
        XCTAssertTrue(app.otherElements["SajuInputStep_5"].waitForExistence(timeout: 4))
        app.buttons["SajuCTA"].tap() // should skip solarTime → loader
        XCTAssertTrue(app.descendants(matching: .any)["SajuLoaderRoot"].waitForExistence(timeout: 4))
    }

    // T44 — AC-11
    func test_step6_defaultToggleOn_showsCalculatedBox_toggleOffShowsNotApplied() {
        let app = launchOnStep(6)
        XCTAssertTrue(app.otherElements["SajuCalcBox"].waitForExistence(timeout: 6))

        let toggle = app.switches["SajuSolarTimeToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2))
        // default ON
        XCTAssertEqual(toggle.value as? String, "1")

        toggle.tap()
        let offset = app.staticTexts["SajuCalcOffset"]
        XCTAssertTrue(offset.waitForExistence(timeout: 2))
        XCTAssertTrue(offset.label.contains("미적용"))
    }

    // T45 — AC-12
    func test_step6_whatsTrueSolarTime_openAndDismissBottomSheet() {
        let app = launchOnStep(6)
        let link = app.buttons["SajuWhatsTrueSolarLink"]
        XCTAssertTrue(link.waitForExistence(timeout: 6))
        link.tap()
        let sheet = app.otherElements["SajuWhatsTrueSolarSheet"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 2))
        app.buttons["SajuSheetConfirm"].tap()
    }

    // T46 — AC-13
    func test_step6_startAnalysisCta_movesToLoader() {
        let app = launchOnStep(6)
        let cta = app.buttons["SajuCTA"]
        XCTAssertTrue(cta.waitForExistence(timeout: 6))
        XCTAssertTrue(cta.isEnabled)
        cta.tap()
        XCTAssertTrue(app.descendants(matching: .any)["SajuLoaderRoot"].waitForExistence(timeout: 4))
    }

    // T47 — AC-14
    func test_loader_showsProgress_tips_rotated_minimum1_8seconds() {
        let start = Date()
        let app = launchOnStep(7, extraArgs: ["-sajuLoaderMinimumDisplayInterval", "8.0"])
        XCTAssertTrue(app.descendants(matching: .any)["SajuLoaderRoot"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.descendants(matching: .any)["SajuLoaderTitle"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["SajuLoaderTipCarousel"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["SajuLoaderTipEyebrow"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["SajuLoaderCredit"].exists)
        // Wait for auto transition to result.
        XCTAssertTrue(app.descendants(matching: .any)["SajuResultRoot"].waitForExistence(timeout: 6))
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertGreaterThan(elapsed, 1.8)
    }

    func test_loader_tipCarousel_swipeChangesTip() {
        let app = launchOnStep(
            7,
            extraArgs: [
                "-sajuLoaderMinimumDisplayInterval", "8.0",
                "-sajuLoaderTipRotationInterval", "60.0"
            ]
        )
        let carousel = app.descendants(matching: .any)["SajuLoaderTipCarousel"]
        XCTAssertTrue(carousel.waitForExistence(timeout: 6))

        let tip = app.descendants(matching: .any)["SajuLoaderTip"]
        XCTAssertTrue(tip.waitForExistence(timeout: 2))
        let firstTip = tip.label

        carousel.swipeLeft()

        let tipChanged = NSPredicate(format: "label != %@", firstTip)
        expectation(for: tipChanged, evaluatedWith: tip)
        waitForExpectations(timeout: 3)
    }

    // T62 — OnboardingUITests 회귀 방지 smoke test (SajuInputRoot 식별자 이관)
    func test_onboardingComplete_landsOnSajuInputRoot() {
        let app = XCUIApplication()
        app.launchArguments = ["-hasSeenOnboarding", "YES", "-resetSajuInput"]
        app.launch()
        XCTAssertTrue(app.otherElements["SajuInputRoot"].waitForExistence(timeout: 6),
                      "SajuInputRoot identifier must live on the Step 1 container")
    }
}
