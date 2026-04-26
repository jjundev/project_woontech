import XCTest

final class EventDetailUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Launch with -openHome and navigate to EventDetailView via HomeNavPushEvent.
    private func launchAndPushEvent(_ extraArgs: [String] = [], extraEnv: [String: String] = [:]) {
        app.launchArguments = ["-openHome"] + extraArgs
        for (key, value) in extraEnv {
            app.launchEnvironment[key] = value
        }
        app.launch()
        let root = app.otherElements["HomeDashboardRoot"]
        XCTAssertTrue(root.waitForExistence(timeout: 10), "HomeDashboardRoot should appear")
        let navButton = app.buttons["HomeNavPushEvent"]
        XCTAssertTrue(navButton.waitForExistence(timeout: 10), "HomeNavPushEvent should exist")
        navButton.tap()
        let title = app.staticTexts["EventDetailTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 10), "EventDetailTitle should appear after push")
    }

    // MARK: - UI1: HomeNavPushEvent → EventDetailTitle exists (AC-1)

    func testHomeNavPushEvent_pushesEventDetailView() {
        launchAndPushEvent()
        XCTAssertTrue(app.staticTexts["EventDetailTitle"].exists)
    }

    // MARK: - UI2: EventCardView tap → EventDetailTitle (AC-1)

    func testEventCardTap_pushesEventDetailView() {
        app.launchArguments = ["-openHome"]
        app.launch()
        let root = app.otherElements["HomeDashboardRoot"]
        XCTAssertTrue(root.waitForExistence(timeout: 10))
        // Scroll to reveal event cards
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "A ScrollView should exist")
        // Find the first mock event card by its title label (MockWeeklyEventsProvider events()[0].title)
        let eventLabel = app.staticTexts["곡우(穀雨)"]
        if !eventLabel.waitForExistence(timeout: 5) {
            for _ in 0..<4 { scrollView.swipeUp() }
        }
        XCTAssertTrue(eventLabel.waitForExistence(timeout: 10), "An event card label should exist")
        eventLabel.tap()
        let title = app.staticTexts["EventDetailTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 10), "EventDetailTitle should appear after card tap")
    }

    // MARK: - UI3: NavBar title label == "이벤트 상세" (AC-2)

    func testNavBarTitle_isEventDetail() {
        launchAndPushEvent()
        let navTitle = app.staticTexts["EventDetailTitle"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5))
        XCTAssertEqual(navTitle.label, "이벤트 상세")
    }

    // MARK: - UI4: EventDetailBackButton + EventDetailShareButton exist (AC-2)

    func testNavBarButtons_exist() {
        launchAndPushEvent()
        XCTAssertTrue(app.buttons["EventDetailBackButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["EventDetailShareButton"].waitForExistence(timeout: 5))
    }

    // MARK: - UI5: Title card contains event info (AC-2)

    func testTitleCard_containsEventInfo() {
        launchAndPushEvent()
        // Title card container
        let titleCard = app.otherElements["EventDetailTitleCard"]
        XCTAssertTrue(titleCard.waitForExistence(timeout: 5))
        // Event from MockWeeklyEventsProvider().events()[0]: 대운 전환, 🔄, dday=-89, ddayDate="2026.05.12"
        // icon: "🔄", title: "대운 전환", oneLiner: "새로운 10년 주기 — 병진 대운 진입"
        // ddayDate: "2026.05.12", D-day: "D-89"
        XCTAssertTrue(app.staticTexts["대운 전환"].exists || titleCard.staticTexts["대운 전환"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '2026.05.12'")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'D-89'")).firstMatch.exists)
    }

    // MARK: - UI6: Badge pill — visible when badge non-nil, hidden when nil (AC-2)

    func testBadgePill_visibleForDefaultEvent() {
        // Default event (events()[0]) has badge "중요"
        launchAndPushEvent()
        let badgePill = app.staticTexts["EventDetailBadgePill"]
        XCTAssertTrue(badgePill.waitForExistence(timeout: 5), "Badge pill should be visible for event with badge")
    }

    // MARK: - UI7: MeaningSection + MeaningText (AC-3)

    func testMeaningSection_exists_withDefaultContent() {
        launchAndPushEvent()
        let section = app.otherElements["EventDetailMeaningSection"]
        XCTAssertTrue(section.waitForExistence(timeout: 5))
        let text = app.staticTexts["EventDetailMeaningText"]
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        XCTAssertTrue(text.label.contains("10년 주기로 바뀌는"))
    }

    // MARK: - UI8: SajuFormula + SajuNote default mock strings (AC-4)

    func testSajuSection_formulaAndNote() {
        launchAndPushEvent()
        let formula = app.staticTexts["EventDetailSajuFormula"]
        XCTAssertTrue(formula.waitForExistence(timeout: 5))
        XCTAssertTrue(formula.label.contains("경금 일주 × 병진 대운 = 편관"))
        let note = app.staticTexts["EventDetailSajuNote"]
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        XCTAssertTrue(note.label.contains("압박과 성장이 공존하는 10년"))
    }

    // MARK: - UI9: Default mock — InvestBullet_0/1/2 all exist (AC-5)

    func testInvestSection_threeBulletsExist() {
        launchAndPushEvent()
        XCTAssertTrue(app.otherElements["EventDetailInvestBullet_0"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["EventDetailInvestBullet_1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["EventDetailInvestBullet_2"].waitForExistence(timeout: 5))
    }

    // MARK: - UI10: -mockEmptyInvestPerspectives → InvestSection absent (AC-5)

    func testInvestSection_hiddenWhenEmpty() {
        launchAndPushEvent(["-mockEmptyInvestPerspectives"])
        // Give time for navigation to settle
        let _ = app.staticTexts["EventDetailTitle"].waitForExistence(timeout: 10)
        // Scroll through to be sure
        for _ in 0..<3 { app.swipeUp() }
        XCTAssertFalse(app.otherElements["EventDetailInvestSection"].exists,
                       "InvestSection should be absent when investPerspectives is empty")
    }

    // MARK: - UI11: ActionButtons container with 3 buttons (AC-6)

    func testActionButtons_threButtonsExist() {
        launchAndPushEvent()
        // Scroll to reveal action buttons if needed
        if !app.buttons["EventDetailBellButton"].waitForExistence(timeout: 5) {
            for _ in 0..<3 { app.swipeUp() }
        }
        XCTAssertTrue(app.buttons["EventDetailBellButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["EventDetailCalendarButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["EventDetailLearnButton"].waitForExistence(timeout: 5))
    }

    // MARK: - UI12: LearnButton label == default learnCTAText (AC-6)

    func testLearnButton_label_isDefaultLearnCTAText() {
        launchAndPushEvent()
        if !app.buttons["EventDetailLearnButton"].waitForExistence(timeout: 5) {
            for _ in 0..<3 { app.swipeUp() }
        }
        let learnButton = app.buttons["EventDetailLearnButton"]
        XCTAssertTrue(learnButton.waitForExistence(timeout: 5))
        XCTAssertEqual(learnButton.label, "📖 대운 학습하기 →")
    }

    // MARK: - UI13: BellButton tap → spy counter increments (AC-7)

    func testBellButtonTap_incrementsSpyCounter() {
        launchAndPushEvent()
        if !app.buttons["EventDetailBellButton"].waitForExistence(timeout: 5) {
            for _ in 0..<3 { app.swipeUp() }
        }
        let counter = app.staticTexts["EventDetailBellTapCount"]
        XCTAssertTrue(counter.waitForExistence(timeout: 5))
        let beforeValue = Int(counter.label) ?? 0

        app.buttons["EventDetailBellButton"].tap()

        XCTAssertEqual(Int(counter.label) ?? -1, beforeValue + 1)
    }

    // MARK: - UI14: CalendarButton tap → spy counter increments (AC-8)

    func testCalendarButtonTap_incrementsSpyCounter() {
        launchAndPushEvent()
        if !app.buttons["EventDetailCalendarButton"].waitForExistence(timeout: 5) {
            for _ in 0..<3 { app.swipeUp() }
        }
        let counter = app.staticTexts["EventDetailCalendarTapCount"]
        XCTAssertTrue(counter.waitForExistence(timeout: 5))
        let beforeValue = Int(counter.label) ?? 0

        app.buttons["EventDetailCalendarButton"].tap()

        XCTAssertEqual(Int(counter.label) ?? -1, beforeValue + 1)
    }

    // MARK: - UI15: LearnButton tap → spy counter increments (AC-9)

    func testLearnButtonTap_incrementsSpyCounter() {
        launchAndPushEvent()
        if !app.buttons["EventDetailLearnButton"].waitForExistence(timeout: 5) {
            for _ in 0..<3 { app.swipeUp() }
        }
        let counter = app.staticTexts["EventDetailLearnTapCount"]
        XCTAssertTrue(counter.waitForExistence(timeout: 5))
        let beforeValue = Int(counter.label) ?? 0

        app.buttons["EventDetailLearnButton"].tap()

        XCTAssertEqual(Int(counter.label) ?? -1, beforeValue + 1)
    }

    // MARK: - UI16: ShareButton tap → spy counter increments (AC-10)

    func testShareButtonTap_incrementsSpyCounter() {
        launchAndPushEvent()
        let counter = app.staticTexts["EventDetailShareTapCount"]
        XCTAssertTrue(counter.waitForExistence(timeout: 5))
        let beforeValue = Int(counter.label) ?? 0

        app.buttons["EventDetailShareButton"].tap()

        XCTAssertEqual(Int(counter.label) ?? -1, beforeValue + 1)
    }

    // MARK: - UI17: BackButton tap → returns to HomeDashboardRoot (AC-11)

    func testBackButtonTap_popsToHome() {
        launchAndPushEvent()
        let backButton = app.buttons["EventDetailBackButton"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.tap()
        XCTAssertTrue(app.otherElements["HomeDashboardRoot"].waitForExistence(timeout: 5))
    }

    // MARK: - UI18: Disclaimer at scroll bottom (AC-12)

    func testDisclaimer_existsAtBottom() {
        launchAndPushEvent()
        let disclaimer = app.staticTexts["DisclaimerText"]
        if !disclaimer.waitForExistence(timeout: 3) {
            for _ in 0..<5 where !disclaimer.exists {
                app.swipeUp()
            }
        }
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 5), "DisclaimerText should appear at bottom of EventDetailView")
    }

    // MARK: - UI19: Dynamic Type XL — meaning + bullet not truncated (AC-14)

    func testDynamicTypeXL_noTruncation() {
        launchAndPushEvent([], extraEnv: ["UIContentSizeCategoryOverride": "UICTContentSizeCategoryAccessibilityXL"])

        let meaningText = app.staticTexts["EventDetailMeaningText"]
        XCTAssertTrue(meaningText.waitForExistence(timeout: 10))
        XCTAssertGreaterThan(meaningText.frame.height, 0)
        XCTAssertFalse(meaningText.label.contains("…"), "Meaning text should not be truncated at XL")

        if !app.otherElements["EventDetailInvestBullet_0"].waitForExistence(timeout: 3) {
            for _ in 0..<3 where !app.otherElements["EventDetailInvestBullet_0"].exists {
                app.swipeUp()
            }
        }
        let bullet0 = app.otherElements["EventDetailInvestBullet_0"]
        XCTAssertTrue(bullet0.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(bullet0.frame.height, 0)
    }

    // MARK: - UI20: -mockCustomMeaning + -mockCustomLearnCTA → bindings (AC-13)

    func testCustomMeaningAndLearnCTA_bindingsReflected() {
        launchAndPushEvent(["-mockCustomMeaning", "커스텀의미텍스트", "-mockCustomLearnCTA", "커스텀CTA텍스트"])

        let meaningText = app.staticTexts["EventDetailMeaningText"]
        XCTAssertTrue(meaningText.waitForExistence(timeout: 10))
        XCTAssertTrue(meaningText.label.contains("커스텀의미텍스트"), "MeaningText should contain custom meaning")

        if !app.buttons["EventDetailLearnButton"].waitForExistence(timeout: 5) {
            for _ in 0..<3 { app.swipeUp() }
        }
        let learnButton = app.buttons["EventDetailLearnButton"]
        XCTAssertTrue(learnButton.waitForExistence(timeout: 5))
        XCTAssertEqual(learnButton.label, "커스텀CTA텍스트")
    }

    // MARK: - UI21: -mockCustomSajuFormula → SajuFormula binding (AC-13)

    func testCustomSajuFormula_bindingReflected() {
        launchAndPushEvent(["-mockCustomSajuFormula", "커스텀공식"])

        let formulaText = app.staticTexts["EventDetailSajuFormula"]
        XCTAssertTrue(formulaText.waitForExistence(timeout: 10))
        XCTAssertTrue(formulaText.label.contains("커스텀공식"), "SajuFormula should contain custom formula")
    }
}
