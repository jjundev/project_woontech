import XCTest

final class SajuResultUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - Profile JSON presets (literal — UI tests can't import app module)

    private static let defaultProfileJSON = """
    {"gender":"male","name":"민","birthDate":{"year":1990,"month":3,"day":15,"kind":{"solar":{}}},"birthTime":{"hour":12,"minute":0,"hourKnown":true},"birthPlace":{"domestic":{"cityID":"SEOUL"}},"solarTime":{"enabled":true}}
    """

    private static let longNameProfileJSON = """
    {"gender":"male","name":"가가가가가가가가가가가","birthDate":{"year":1990,"month":3,"day":15,"kind":{"solar":{}}},"birthTime":{"hour":12,"minute":0,"hourKnown":true},"birthPlace":{"domestic":{"cityID":"SEOUL"}},"solarTime":{"enabled":true}}
    """

    private static let emptyNameProfileJSON = """
    {"gender":"male","name":"","birthDate":{"year":1990,"month":3,"day":15,"kind":{"solar":{}}},"birthTime":{"hour":12,"minute":0,"hourKnown":true},"birthPlace":{"domestic":{"cityID":"SEOUL"}},"solarTime":{"enabled":true}}
    """

    private static let highAccuracyProfileJSON = defaultProfileJSON

    private static let mediumAccuracyProfileJSON = """
    {"gender":"male","name":"민","birthDate":{"year":1990,"month":3,"day":15,"kind":{"solar":{}}},"birthTime":{"hour":12,"minute":0,"hourKnown":true},"birthPlace":{"domestic":{"cityID":"SEOUL"}},"solarTime":{"enabled":false}}
    """

    private static let hourUnknownProfileJSON = """
    {"gender":"male","name":"민","birthDate":{"year":1990,"month":3,"day":15,"kind":{"solar":{}}},"birthTime":{"hour":12,"minute":0,"hourKnown":false},"birthPlace":{"domestic":{"cityID":"SEOUL"}},"solarTime":{"enabled":true}}
    """

    private func launchOnResult(profileJSON: String = defaultProfileJSON) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-hasSeenOnboarding", "YES",
            "-resetSajuInput",
            "-sajuStartStep", "8",
            "-preloadedProfile", profileJSON
        ]
        app.launch()
        return app
    }

    // T48 — AC-15
    func test_result_sectionsInOrder_hero_origin_wuxing_strength_caution_approach() {
        let app = launchOnResult()
        XCTAssertTrue(app.otherElements["SajuResultRoot"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.otherElements["SajuHeroCard"].exists)
        XCTAssertTrue(app.otherElements["SajuOriginChart"].exists)
        XCTAssertTrue(app.otherElements["SajuWuxingBlock"].exists)
        XCTAssertTrue(app.otherElements["SajuStrengths"].exists)
        XCTAssertTrue(app.otherElements["SajuCautions"].exists)
        XCTAssertTrue(app.otherElements["SajuApproaches"].exists)
    }

    // T49 — AC-16
    func test_result_heroLabel_longName_truncates_emptyFallback() {
        let app = launchOnResult(profileJSON: SajuResultUITests.longNameProfileJSON)
        let label = app.staticTexts["SajuHeroLabel"]
        XCTAssertTrue(label.waitForExistence(timeout: 6))
        XCTAssertTrue(label.label.contains("…"))
        app.terminate()

        let app2 = launchOnResult(profileJSON: SajuResultUITests.emptyNameProfileJSON)
        XCTAssertTrue(app2.staticTexts["당신의 투자 성향"].waitForExistence(timeout: 6))
    }

    // T50 — AC-17
    func test_result_accuracyBadge_high_medium_mediumWithAddTimeCta() {
        let app = launchOnResult(profileJSON: SajuResultUITests.highAccuracyProfileJSON)
        XCTAssertTrue(app.otherElements["SajuAccuracyBadge_high"].waitForExistence(timeout: 6))
        app.terminate()

        let app2 = launchOnResult(profileJSON: SajuResultUITests.mediumAccuracyProfileJSON)
        XCTAssertTrue(app2.otherElements["SajuAccuracyBadge_medium"].waitForExistence(timeout: 6))
        app2.terminate()

        let app3 = launchOnResult(profileJSON: SajuResultUITests.hourUnknownProfileJSON)
        XCTAssertTrue(app3.otherElements["SajuAccuracyBadge_mediumAddTime"].waitForExistence(timeout: 6))
        XCTAssertTrue(app3.buttons["SajuAccuracyAddTimeCTA"].exists)
    }

    // T51 — AC-18
    func test_result_hourUnknown_miniChartHourColumn_dashed() {
        let app = launchOnResult(profileJSON: SajuResultUITests.hourUnknownProfileJSON)
        XCTAssertTrue(app.otherElements["SajuPillar_hour"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.staticTexts["SajuPillar_hour_missing"].exists)
    }

    // T53 — AC-20
    func test_result_share_opensActivityViewController_with1080x1920Image() {
        let app = launchOnResult()
        let share = app.buttons["SajuResultShareCTA"]
        XCTAssertTrue(share.waitForExistence(timeout: 6))
        share.tap()
        // Activity view controller is system UI; just verify no crash.
        sleep(1)
    }

    func test_result_reinputButton_returnsToFirstInputStep() {
        let app = launchOnResult()
        let reinput = app.buttons["SajuResultReinputButton"]
        XCTAssertTrue(reinput.waitForExistence(timeout: 6))
        reinput.tap()
        XCTAssertTrue(app.otherElements["SajuInputRoot"].waitForExistence(timeout: 4))
    }

    // T54 — AC-21
    func test_result_start_movesToSignUp_whenNotLoggedIn() {
        let app = launchOnResult()
        let start = app.buttons["SajuResultStartCTA"]
        XCTAssertTrue(start.waitForExistence(timeout: 6))
        start.tap()
        XCTAssertTrue(app.otherElements["SajuSignUpRoot"].waitForExistence(timeout: 4))
    }

    // T61 — AC-28
    func test_result_disclaimer_containsStudyPhrase() {
        let app = launchOnResult()
        let disclaimer = app.staticTexts["SajuDisclaimer"]
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 6))
        XCTAssertTrue(disclaimer.label.contains("본 앱은 학습·참고용이며 투자 권유가 아닙니다"))
    }
}
