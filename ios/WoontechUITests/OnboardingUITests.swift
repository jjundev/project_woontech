import XCTest

final class OnboardingUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - Helpers

    private func launchFresh(hasSeenOnboarding: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        var args = ["-resetOnboarding"]
        if hasSeenOnboarding {
            args = ["-hasSeenOnboarding", "YES"]
        }
        app.launchArguments = args
        app.launch()
        return app
    }

    private func waitForOnboarding1(_ app: XCUIApplication, timeout: TimeInterval = 6) {
        let title = app.staticTexts["OnboardingTitle_1"]
        XCTAssertTrue(title.waitForExistence(timeout: timeout),
                      "Expected onboarding step 1 to appear after splash")
    }

    private func tapCTA(_ app: XCUIApplication) {
        let cta = app.buttons["OnboardingCTA"]
        XCTAssertTrue(cta.waitForExistence(timeout: 2))
        cta.tap()
    }

    private func swipeLeftOnStep(_ app: XCUIApplication) {
        app.otherElements["OnboardingRoot"].swipeLeft()
    }

    private func swipeRightOnStep(_ app: XCUIApplication) {
        app.otherElements["OnboardingRoot"].swipeRight()
    }

    // MARK: - AC-1, AC-2

    func test_coldLaunch_showsSplash_thenOnboarding1() {
        let app = launchFresh()

        let splash = app.otherElements["SplashRoot"]
        XCTAssertTrue(splash.waitForExistence(timeout: 2), "Splash should appear immediately")

        waitForOnboarding1(app)
    }

    func test_allThreeSteps_showCorrectStrings() {
        let app = launchFresh()
        waitForOnboarding1(app)

        XCTAssertTrue(app.staticTexts["내 사주로 투자 성향 진단"].exists)
        XCTAssertTrue(app.staticTexts["생년월일시를 입력하면\n나만의 투자 성향을 알려드려요"].exists)

        tapCTA(app)
        XCTAssertTrue(app.staticTexts["매일 바뀌는 내 투자 리스크 점검"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["오늘 나의 투자 감정과 리스크를\n사주 기반으로 점검해드려요"].exists)

        tapCTA(app)
        XCTAssertTrue(app.staticTexts["실전 전에 모의 투자"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["내 성향과 오늘의 흐름으로\n부담 없이 연습해보세요"].exists)
    }

    // MARK: - AC-3 CTA advances

    func test_ctaTap_movesStep1_to_Step2_to_Step3() {
        let app = launchFresh()
        waitForOnboarding1(app)

        tapCTA(app)
        XCTAssertTrue(app.staticTexts["OnboardingTitle_2"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.otherElements["OnboardingIndicator_2"].isSelected)

        tapCTA(app)
        XCTAssertTrue(app.staticTexts["OnboardingTitle_3"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.otherElements["OnboardingIndicator_3"].isSelected)
    }

    // MARK: - AC-4 swipe advance/return

    func test_leftSwipe_advancesStep_rightSwipeReturns() {
        let app = launchFresh()
        waitForOnboarding1(app)

        swipeLeftOnStep(app)
        XCTAssertTrue(app.staticTexts["OnboardingTitle_2"].waitForExistence(timeout: 2))

        swipeLeftOnStep(app)
        XCTAssertTrue(app.staticTexts["OnboardingTitle_3"].waitForExistence(timeout: 2))

        swipeRightOnStep(app)
        XCTAssertTrue(app.staticTexts["OnboardingTitle_2"].waitForExistence(timeout: 2))

        swipeRightOnStep(app)
        XCTAssertTrue(app.staticTexts["OnboardingTitle_1"].waitForExistence(timeout: 2))
    }

    // MARK: - AC-5 boundary swipes

    func test_swipeBoundaries_step1Right_step3Left_noop() {
        let app = launchFresh()
        waitForOnboarding1(app)

        swipeRightOnStep(app)
        XCTAssertTrue(app.staticTexts["OnboardingTitle_1"].exists)

        app.otherElements["OnboardingIndicator_3"].tap()
        XCTAssertTrue(app.staticTexts["OnboardingTitle_3"].waitForExistence(timeout: 2))

        swipeLeftOnStep(app)
        XCTAssertTrue(app.staticTexts["OnboardingTitle_3"].exists)
    }

    // MARK: - AC-6 indicator tap jumps

    func test_indicatorTap_jumpsToStep() {
        let app = launchFresh()
        waitForOnboarding1(app)

        app.otherElements["OnboardingIndicator_3"].tap()
        XCTAssertTrue(app.staticTexts["OnboardingTitle_3"].waitForExistence(timeout: 2))

        app.otherElements["OnboardingIndicator_1"].tap()
        XCTAssertTrue(app.staticTexts["OnboardingTitle_1"].waitForExistence(timeout: 2))

        app.otherElements["OnboardingIndicator_2"].tap()
        XCTAssertTrue(app.staticTexts["OnboardingTitle_2"].waitForExistence(timeout: 2))
    }

    // MARK: - AC-7 skip persists flag and exits

    func test_skipTap_anyStep_goesToSajuInput_andPersistsFlag() {
        for startStep in 1...3 {
            let app = launchFresh()
            waitForOnboarding1(app)
            if startStep > 1 {
                app.otherElements["OnboardingIndicator_\(startStep)"].tap()
                XCTAssertTrue(app.staticTexts["OnboardingTitle_\(startStep)"].waitForExistence(timeout: 2))
            }
            app.buttons["OnboardingSkipButton"].tap()

            XCTAssertTrue(app.otherElements["SajuInputRoot"].waitForExistence(timeout: 2),
                          "Skip from step \(startStep) should land on SajuInputRoot")
            app.terminate()

            let relaunch = XCUIApplication()
            relaunch.launchArguments = []
            relaunch.launch()
            XCTAssertTrue(relaunch.otherElements["SajuInputRoot"].waitForExistence(timeout: 6),
                          "Flag should persist so next launch bypasses onboarding")
            relaunch.terminate()
        }
    }

    // MARK: - AC-8, AC-10 step3 disclaimer disables CTA

    func test_step3_disclaimerUnchecked_ctaDisabled_tapNoop() {
        let app = launchFresh()
        waitForOnboarding1(app)

        app.otherElements["OnboardingIndicator_3"].tap()
        XCTAssertTrue(app.staticTexts["OnboardingTitle_3"].waitForExistence(timeout: 2))

        let checkbox = app.buttons["OnboardingDisclaimerCheckbox"]
        XCTAssertTrue(checkbox.exists)
        XCTAssertFalse(checkbox.isSelected, "Disclaimer should default to unchecked")

        let cta = app.buttons["OnboardingCTA"]
        XCTAssertFalse(cta.isEnabled, "CTA should be disabled while disclaimer unchecked")

        cta.tap()
        XCTAssertTrue(app.staticTexts["OnboardingTitle_3"].exists,
                      "Tapping disabled CTA should not navigate")
        XCTAssertFalse(app.otherElements["SajuInputRoot"].exists)
    }

    // MARK: - AC-9 toggle enables/disables CTA

    func test_step3_checkToggle_enablesAndDisablesCTA() {
        let app = launchFresh()
        waitForOnboarding1(app)
        app.otherElements["OnboardingIndicator_3"].tap()
        XCTAssertTrue(app.staticTexts["OnboardingTitle_3"].waitForExistence(timeout: 2))

        let checkbox = app.buttons["OnboardingDisclaimerCheckbox"]
        let cta = app.buttons["OnboardingCTA"]

        XCTAssertFalse(cta.isEnabled)
        checkbox.tap()
        XCTAssertTrue(cta.isEnabled)
        checkbox.tap()
        XCTAssertFalse(cta.isEnabled)
    }

    // MARK: - AC-11 checked start navigates and persists

    func test_step3_checkedStart_navigatesSaju_andPersistsFlag() {
        let app = launchFresh()
        waitForOnboarding1(app)
        app.otherElements["OnboardingIndicator_3"].tap()
        XCTAssertTrue(app.staticTexts["OnboardingTitle_3"].waitForExistence(timeout: 2))

        app.buttons["OnboardingDisclaimerCheckbox"].tap()
        app.buttons["OnboardingCTA"].tap()

        XCTAssertTrue(app.otherElements["SajuInputRoot"].waitForExistence(timeout: 2))
        app.terminate()

        let relaunch = XCUIApplication()
        relaunch.launchArguments = []
        relaunch.launch()
        XCTAssertTrue(relaunch.otherElements["SajuInputRoot"].waitForExistence(timeout: 6))
    }

    // MARK: - AC-12 relaunch with flag bypasses onboarding

    func test_relaunch_whenFlagTrue_bypassesOnboarding() {
        let app = launchFresh(hasSeenOnboarding: true)

        XCTAssertTrue(app.otherElements["SplashRoot"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.otherElements["SajuInputRoot"].waitForExistence(timeout: 6))
        XCTAssertFalse(app.staticTexts["OnboardingTitle_1"].exists)
    }

    // MARK: - AC-13 VoiceOver labels

    func test_voiceOverLabels_present() {
        let app = launchFresh()
        waitForOnboarding1(app)

        XCTAssertFalse(app.buttons["OnboardingSkipButton"].label.isEmpty)
        XCTAssertFalse(app.otherElements["OnboardingIndicator_1"].label.isEmpty)
        XCTAssertFalse(app.otherElements["OnboardingIndicator_2"].label.isEmpty)
        XCTAssertFalse(app.otherElements["OnboardingIndicator_3"].label.isEmpty)

        app.otherElements["OnboardingIndicator_3"].tap()
        XCTAssertTrue(app.staticTexts["OnboardingTitle_3"].waitForExistence(timeout: 2))
        let checkbox = app.buttons["OnboardingDisclaimerCheckbox"]
        XCTAssertFalse(checkbox.label.isEmpty)
        XCTAssertFalse(checkbox.isSelected)
        checkbox.tap()
        XCTAssertTrue(checkbox.isSelected)
    }

    // MARK: - AC-14 hit target sizes

    func test_accessibility_hitTargets_minimum44pt() {
        let app = launchFresh()
        waitForOnboarding1(app)

        let skip = app.buttons["OnboardingSkipButton"]
        XCTAssertGreaterThanOrEqual(skip.frame.width, 44)
        XCTAssertGreaterThanOrEqual(skip.frame.height, 44)

        for i in 1...3 {
            let dot = app.otherElements["OnboardingIndicator_\(i)"]
            XCTAssertGreaterThanOrEqual(dot.frame.width, 44, "Dot \(i) width < 44pt")
            XCTAssertGreaterThanOrEqual(dot.frame.height, 44, "Dot \(i) height < 44pt")
        }
    }
}
