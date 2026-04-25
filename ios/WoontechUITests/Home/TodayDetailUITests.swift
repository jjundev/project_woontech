import XCTest

final class TodayDetailUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launchAndPushToday(_ extraArgs: [String] = []) {
        app.launchArguments = ["-openHome"] + extraArgs
        app.launch()
        let root = app.otherElements["HomeDashboardRoot"]
        XCTAssertTrue(root.waitForExistence(timeout: 5), "HomeDashboardRoot should appear")
        let nav = app.buttons["HomeNavPushToday"]
        XCTAssertTrue(nav.waitForExistence(timeout: 5))
        nav.tap()
        let title = app.staticTexts["TodayDetailTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5), "TodayDetailTitle should appear")
    }

    // MARK: - UI1: Insights 일진 카드 탭 → push (AC-1)

    func testInsightsTodayCardTap_pushesTodayDetail() {
        app.launchArguments = ["-openHome"]
        app.launch()
        // InsightCardView is a SwiftUI Button — must query via .buttons, not .otherElements.
        let card = app.buttons["HomeInsightsCard_1"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        let title = app.staticTexts["TodayDetailTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
    }

    // MARK: - UI2: NavBar title + Back (AC-2)

    func testNavBarTitleAndBack() {
        launchAndPushToday()
        XCTAssertEqual(app.staticTexts["TodayDetailTitle"].label, "오늘의 일진")
        let backButton = app.buttons["TodayDetailBackButton"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.tap()
        XCTAssertTrue(app.otherElements["HomeDashboardRoot"].waitForExistence(timeout: 5))
    }

    // MARK: - UI3: 4기둥 렌더 (AC-3, AC-15)

    func testSajuOriginRendersFourPillars() {
        launchAndPushToday()
        XCTAssertTrue(app.otherElements["SajuPillar_year"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["SajuPillar_month"].exists)
        XCTAssertTrue(app.otherElements["SajuPillar_day"].exists)
        XCTAssertTrue(app.otherElements["SajuPillar_hour"].exists)
    }

    // MARK: - UI4: 5칸 오행 분포 (AC-4)

    func testWuxingDistributionFiveCellsOrder() {
        launchAndPushToday()
        let woodCell = app.otherElements["WuxingCell_wood"]
        XCTAssertTrue(woodCell.waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["WuxingCell_fire"].exists)
        XCTAssertTrue(app.otherElements["WuxingCell_earth"].exists)
        XCTAssertTrue(app.otherElements["WuxingCell_metal"].exists)
        XCTAssertTrue(app.otherElements["WuxingCell_water"].exists)
        // wood: 한자 木, count 1
        XCTAssertTrue(woodCell.label.contains("木"))
        XCTAssertTrue(woodCell.label.contains("1"))
    }

    // MARK: - UI5: weakElement warning (AC-5)

    func testWeakElementWarningRendered() {
        launchAndPushToday()
        let warning = app.staticTexts["WuxingWarningText"]
        XCTAssertTrue(warning.waitForExistence(timeout: 5))
        XCTAssertTrue(warning.label.contains("水 부족"))
    }

    // MARK: - UI6: 십성 stamp (AC-6)

    func testSipseongStamp() {
        launchAndPushToday()
        let stampName = app.staticTexts["SipseongStampName"]
        let stampHanja = app.staticTexts["SipseongStampHanja"]
        XCTAssertTrue(stampName.waitForExistence(timeout: 5))
        XCTAssertEqual(stampName.label, "편관")
        XCTAssertEqual(stampHanja.label, "偏官")
    }

    // MARK: - UI7: 십성 우측 3줄 (AC-7)

    func testSipseongRightSideThreeLines() {
        launchAndPushToday()
        XCTAssertTrue(app.staticTexts["SipseongOneLiner"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["SipseongRelation"].exists)
        XCTAssertTrue(app.staticTexts["SipseongExamples"].exists)
    }

    // MARK: - UI8: 합충 row 순서 (AC-8)

    func testHapchungRowsRenderInOrder() {
        launchAndPushToday()
        let row0 = app.otherElements["HapchungRow_0"]
        let row1 = app.otherElements["HapchungRow_1"]
        XCTAssertTrue(row0.waitForExistence(timeout: 5))
        XCTAssertTrue(row1.exists)
        XCTAssertTrue(row0.label.contains("申"))
        XCTAssertTrue(row0.label.contains("巳"))
        XCTAssertTrue(row1.label.contains("卯"))
        XCTAssertTrue(row1.label.contains("酉"))
    }

    // MARK: - UI9: 빈 hapchung 카드 숨김 (AC-8)

    func testHapchungCardHiddenWhenEmpty() {
        launchAndPushToday(["-mockTodayHapchungEmpty"])
        XCTAssertFalse(app.otherElements["HapchungSection"].exists)
        XCTAssertFalse(app.otherElements["HapchungRow_0"].exists)
    }

    // MARK: - UI10: negative row styling (AC-9)

    func testHapchungNegativeRowStyling() {
        launchAndPushToday()
        let row1 = app.otherElements["HapchungRow_1"]
        XCTAssertTrue(row1.waitForExistence(timeout: 5))
        XCTAssertTrue(row1.label.contains("−18") || row1.label.contains("-18"))
        XCTAssertTrue(app.otherElements["HapchungRow_1_NegativeStyle"].exists)
    }

    // MARK: - UI11: score formatting (AC-10)

    func testHapchungScoreFormatting() {
        launchAndPushToday()
        let row0Score = app.staticTexts["HapchungRow_0_Score"]
        let row1Score = app.staticTexts["HapchungRow_1_Score"]
        XCTAssertTrue(row0Score.waitForExistence(timeout: 5))
        XCTAssertEqual(row0Score.label, "+12")
        XCTAssertTrue(row1Score.exists)
        XCTAssertEqual(row1Score.label, "−18")
    }

    // MARK: - UI12: motto/taboo nil → hidden (AC-11)

    func testDailyMottoTabooHidden_whenNil() {
        launchAndPushToday()
        XCTAssertFalse(app.otherElements["DailyMottoCard"].exists)
        XCTAssertFalse(app.otherElements["DailyTabooCard"].exists)
    }

    // MARK: - UI13: motto/taboo provided → shown (AC-11)

    func testDailyMottoTabooShown_whenProvided() {
        launchAndPushToday(["-mockTodayMottoTabooOn"])
        let mottoCard = app.otherElements["DailyMottoCard"]
        let tabooCard = app.otherElements["DailyTabooCard"]
        XCTAssertTrue(mottoCard.waitForExistence(timeout: 5))
        XCTAssertTrue(tabooCard.exists)
        XCTAssertTrue(app.staticTexts["오늘의 한마디 예시"].exists)
        XCTAssertTrue(app.staticTexts["금기 예시"].exists)
    }

    // MARK: - UI14: Disclaimer at bottom (AC-12)

    func testDisclaimerAtBottom() {
        launchAndPushToday()
        let disclaimer = app.staticTexts["DisclaimerText"]
        // Disclaimer is below the fold; scroll to find it.
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 5) || {
            app.swipeUp()
            app.swipeUp()
            return disclaimer.waitForExistence(timeout: 3)
        }())
    }

    // MARK: - UI16: Dynamic Type XL — score 잘림 없음 (AC-14)

    func testDynamicTypeXL_hapchungWrapsScoreVisible() {
        app.launchEnvironment["UIContentSizeCategoryOverride"] = "UICTContentSizeCategoryAccessibilityXL"
        launchAndPushToday()
        let scoreLabel = app.staticTexts["HapchungRow_0_Score"]
        XCTAssertTrue(scoreLabel.waitForExistence(timeout: 5))
        XCTAssertEqual(scoreLabel.label, "+12")
        XCTAssertGreaterThan(scoreLabel.frame.width, 0)
        XCTAssertGreaterThan(scoreLabel.frame.height, 0)
    }

    // MARK: - UI17: SajuMiniChartView 재사용 (AC-15)

    func testSajuMiniChartViewReused() {
        launchAndPushToday()
        XCTAssertTrue(app.otherElements["SajuOriginChart"].waitForExistence(timeout: 5))
    }
}
