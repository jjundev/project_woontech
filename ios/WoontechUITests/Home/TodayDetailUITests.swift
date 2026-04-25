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
        XCTAssertTrue(root.waitForExistence(timeout: 10), "HomeDashboardRoot should appear")
        let nav = app.buttons["HomeNavPushToday"]
        XCTAssertTrue(nav.waitForExistence(timeout: 10))
        nav.tap()
        let title = app.staticTexts["TodayDetailTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 10), "TodayDetailTitle should appear after push")
    }

    // MARK: - UI1: Insights 일진 카드 탭 → push (AC-1)

    func testInsightsTodayCardTap_pushesTodayDetail() {
        app.launchArguments = ["-openHome"]
        app.launch()
        // SwiftUI's accessibility model can expose InsightCardView either as a
        // button (its root is `Button`) or as an other-element wrapper, depending
        // on whether the outer `.accessibilityIdentifier` modifier ends up on
        // the same accessibility node as the inner `.accessibilityLabel`. Query
        // both to stay robust across SwiftUI versions.
        let asButton = app.buttons["HomeInsightsCard_1"]
        let asOther = app.otherElements["HomeInsightsCard_1"]
        XCTAssertTrue(
            asButton.waitForExistence(timeout: 10) || asOther.waitForExistence(timeout: 5),
            "HomeInsightsCard_1 should exist as either a button or an other element"
        )
        if asButton.exists {
            asButton.tap()
        } else {
            asOther.tap()
        }
        let title = app.staticTexts["TodayDetailTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
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
        if !row0.waitForExistence(timeout: 5) {
            for _ in 0..<4 where !row0.exists {
                app.swipeUp()
            }
        }
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
        // Allow scroll so we exhaust the screen for the section before asserting
        // its absence.
        for _ in 0..<3 { app.swipeUp() }
        XCTAssertFalse(app.otherElements["HapchungSection"].exists)
        XCTAssertFalse(app.otherElements["HapchungRow_0"].exists)
    }

    // MARK: - UI10: negative row styling (AC-9)

    func testHapchungNegativeRowStyling() {
        launchAndPushToday()
        let row1 = app.otherElements["HapchungRow_1"]
        if !row1.waitForExistence(timeout: 5) {
            for _ in 0..<4 where !row1.exists { app.swipeUp() }
        }
        XCTAssertTrue(row1.waitForExistence(timeout: 5))
        XCTAssertTrue(row1.label.contains("−18") || row1.label.contains("-18"))
        XCTAssertTrue(app.otherElements["HapchungRow_1_NegativeStyle"].exists)
    }

    // MARK: - UI11: score formatting (AC-10)

    func testHapchungScoreFormatting() {
        launchAndPushToday()
        let row0Score = app.staticTexts["HapchungRow_0_Score"]
        if !row0Score.waitForExistence(timeout: 5) {
            for _ in 0..<4 where !row0Score.exists { app.swipeUp() }
        }
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
        if !mottoCard.waitForExistence(timeout: 3) {
            for _ in 0..<5 where !mottoCard.exists { app.swipeUp() }
        }
        XCTAssertTrue(mottoCard.waitForExistence(timeout: 5))
        XCTAssertTrue(tabooCard.exists)
        XCTAssertTrue(app.staticTexts["오늘의 한마디 예시"].exists)
        XCTAssertTrue(app.staticTexts["금기 예시"].exists)
    }

    // MARK: - UI14: Disclaimer at bottom (AC-12)

    func testDisclaimerAtBottom() {
        launchAndPushToday()
        let disclaimer = app.staticTexts["DisclaimerText"]
        // Disclaimer is below the fold; scroll until it appears or attempts run out.
        if !disclaimer.waitForExistence(timeout: 3) {
            for _ in 0..<6 where !disclaimer.exists {
                app.swipeUp()
            }
        }
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 5), "DisclaimerText should appear at bottom of TodayDetailView")
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
