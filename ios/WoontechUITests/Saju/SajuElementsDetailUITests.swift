import XCTest

/// UI tests for WF4-04 오행 분포 상세 (`SajuElementsDetailView`).
///
/// 모든 테스트는 `-resetOnboarding -openSajuTab` 으로 앱을 실행하고
/// `SajuNavPush_elements` 히든 트리거를 탭해 `SajuElementsDetailView` 로 진입한다.
final class SajuElementsDetailUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    // MARK: - Helpers

    private func launchSajuTab(extraArgs: [String] = [], extraEnv: [String: String] = [:]) {
        app.launchArguments = ["-resetOnboarding", "-openSajuTab"] + extraArgs
        for (key, value) in extraEnv {
            app.launchEnvironment[key] = value
        }
        app.launch()
        XCTAssertTrue(
            app.otherElements["SajuTabRoot"].waitForExistence(timeout: 5),
            "SajuTabRoot should exist after launch with -openSajuTab"
        )
    }

    /// `SajuElementsDetailView` 로 push 한다.
    private func launchAndPushElementsDetail(
        extraArgs: [String] = [],
        extraEnv: [String: String] = [:]
    ) {
        launchSajuTab(extraArgs: extraArgs, extraEnv: extraEnv)
        let btn = app.buttons["SajuNavPush_elements"]
        XCTAssertTrue(btn.waitForExistence(timeout: 3),
                      "SajuNavPush_elements trigger button must exist")
        btn.tap()
        XCTAssertTrue(
            app.otherElements["SajuElementsDetailView"].waitForExistence(timeout: 5),
            "SajuElementsDetailView must appear after tapping SajuNavPush_elements"
        )
    }

    // MARK: - Navigation (AC#1, AC#2)

    /// T25: `SajuNavPush_elements` 탭 → `SajuElementsDetailView` 존재
    func testNavPush_elements_showsDetailView() {
        launchSajuTab()
        let btn = app.buttons["SajuNavPush_elements"]
        XCTAssertTrue(btn.waitForExistence(timeout: 3))
        btn.tap()
        XCTAssertTrue(
            app.otherElements["SajuElementsDetailView"].waitForExistence(timeout: 5),
            "SajuElementsDetailView should appear after pushing .elements route"
        )
    }

    /// T26: NavBar 타이틀 "오행 분포" (inline 모드 시스템 내비게이션 바)
    func testNavBarTitle_isOhaengBunpo() {
        launchAndPushElementsDetail()
        XCTAssertTrue(
            app.navigationBars.staticTexts["오행 분포"].waitForExistence(timeout: 3),
            "Navigation bar title should read '오행 분포'"
        )
    }

    /// T27: Back 탭 → `SajuTabRoot` visible
    func testBackButton_popsToSajuHome() {
        launchAndPushElementsDetail()
        // System back button is the first (leftmost) button in the navigation bar.
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 3),
                      "System back button must exist in navigation bar")
        backButton.tap()
        XCTAssertTrue(
            app.otherElements["SajuTabRoot"].waitForExistence(timeout: 3),
            "SajuTabRoot should be visible after tapping back"
        )
    }

    // MARK: - Summary Card (AC#3)

    /// T28: `ElementsSummaryHeadline` 존재, label 비어 있지 않음
    func testSummaryCard_headlineVisible() {
        launchAndPushElementsDetail()
        let headline = app.staticTexts["ElementsSummaryHeadline"]
        XCTAssertTrue(headline.waitForExistence(timeout: 3),
                      "ElementsSummaryHeadline must be visible")
        XCTAssertFalse(headline.label.isEmpty,
                       "ElementsSummaryHeadline label must not be empty")
    }

    /// T29: `ElementsSummaryBody` 존재
    func testSummaryCard_bodyVisible() {
        launchAndPushElementsDetail()
        XCTAssertTrue(
            app.staticTexts["ElementsSummaryBody"].waitForExistence(timeout: 3),
            "ElementsSummaryBody must be visible"
        )
    }

    /// T30: `ElementsSummaryHeadline` label == mock 기본값 "火가 많고 水가 전혀 없는 사주"
    func testSummaryCard_headlineEqualsProviderValue() {
        launchAndPushElementsDetail()
        let headline = app.staticTexts["ElementsSummaryHeadline"]
        XCTAssertTrue(headline.waitForExistence(timeout: 3))
        XCTAssertEqual(headline.label, "火가 많고 水가 전혀 없는 사주",
                       "Headline must match MockSajuElementsDetailProvider default")
    }

    // MARK: - 5-Element Distribution (AC#4, AC#5, AC#6)

    /// T31: `ElementRow_火~水` 5개 행 모두 존재
    func testDistribution_fiveRowsExist() {
        launchAndPushElementsDetail()
        let symbols = ["火", "木", "土", "金", "水"]
        for sym in symbols {
            XCTAssertTrue(
                app.otherElements["ElementRow_\(sym)"].waitForExistence(timeout: 3),
                "ElementRow_\(sym) must exist"
            )
        }
    }

    /// T32: 5행 Y좌표 순서 — 火 < 木 < 土 < 金 < 水
    func testDistribution_orderIsFireWoodEarthMetalWater() {
        launchAndPushElementsDetail()
        let symbols = ["火", "木", "土", "金", "水"]
        var prevMaxY: CGFloat = -1
        for sym in symbols {
            let row = app.otherElements["ElementRow_\(sym)"]
            XCTAssertTrue(row.waitForExistence(timeout: 3),
                          "ElementRow_\(sym) must exist for Y-order check")
            let rowMinY = row.frame.minY
            XCTAssertGreaterThan(rowMinY, prevMaxY,
                                 "ElementRow_\(sym) must appear below the previous row")
            prevMaxY = row.frame.maxY
        }
    }

    /// T33: 水 행 접근성 레이블에 "부족" 포함 (isDeficient=true 행)
    func testDistribution_deficientRow_水_noteContains부족() {
        launchAndPushElementsDetail()
        let waterRow = app.otherElements["ElementRow_水"]
        XCTAssertTrue(waterRow.waitForExistence(timeout: 3),
                      "ElementRow_水 must exist")
        XCTAssertTrue(
            waterRow.label.contains("부족"),
            "Water row accessibility label must contain '부족'; got: '\(waterRow.label)'"
        )
    }

    // MARK: - Disclaimer (AC#11)

    /// T34: `DisclaimerText` 존재
    func testDisclaimer_exists() {
        launchAndPushElementsDetail()
        // DisclaimerText may be below the fold; scroll down once to reach it.
        app.scrollViews.firstMatch.swipeUp()
        XCTAssertTrue(
            app.staticTexts["DisclaimerText"].waitForExistence(timeout: 5),
            "DisclaimerText must exist in SajuElementsDetailView"
        )
    }

    /// T35: DisclaimerText 레이블에 "학습·참고용" 포함 (WF1/WF2/WF3과 동일 컴포넌트)
    func testDisclaimer_text_matchesWF1WF2WF3() {
        launchAndPushElementsDetail()
        app.scrollViews.firstMatch.swipeUp()
        let disclaimer = app.staticTexts["DisclaimerText"]
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 5))
        XCTAssertTrue(
            disclaimer.label.contains("학습·참고용"),
            "Disclaimer must contain '학습·참고용'; got: '\(disclaimer.label)'"
        )
    }

    // MARK: - Guidance Card (AC#8, AC#9, AC#10)

    /// T36: `ElementsGuidanceCard` 존재 (default mock — guidance != nil)
    func testGuidanceCard_visibleWithDefaultMock() {
        launchAndPushElementsDetail()
        app.scrollViews.firstMatch.swipeUp()
        XCTAssertTrue(
            app.otherElements["ElementsGuidanceCard"].waitForExistence(timeout: 5),
            "ElementsGuidanceCard must be visible when provider.guidance != nil"
        )
    }

    /// T37: `GuidanceHeader` 레이블에 "水" 포함
    func testGuidanceCard_header_contains水() {
        launchAndPushElementsDetail()
        app.scrollViews.firstMatch.swipeUp()
        let header = app.staticTexts["GuidanceHeader"]
        XCTAssertTrue(header.waitForExistence(timeout: 5),
                      "GuidanceHeader must be visible")
        XCTAssertTrue(
            header.label.contains("水"),
            "GuidanceHeader must contain '水' (targetSymbol); got: '\(header.label)'"
        )
    }

    /// T38: `GuidanceBullet_direction~action` 4개 bullet 모두 존재
    func testGuidanceCard_fourBullets_exist() {
        launchAndPushElementsDetail()
        app.scrollViews.firstMatch.swipeUp()
        let keys = ["direction", "color", "time", "action"]
        for key in keys {
            XCTAssertTrue(
                app.otherElements["GuidanceBullet_\(key)"].waitForExistence(timeout: 5),
                "GuidanceBullet_\(key) must exist"
            )
        }
    }

    /// T39: `-sajuElementsNoGuidance` launch arg → `ElementsGuidanceCard` 미존재 (AC#9)
    func testGuidanceCard_hiddenWhenGuidanceNil() {
        launchAndPushElementsDetail(extraArgs: ["-sajuElementsNoGuidance"])
        app.scrollViews.firstMatch.swipeUp()
        // Give the UI a moment to settle before asserting absence.
        let _ = app.staticTexts["DisclaimerText"].waitForExistence(timeout: 5)
        XCTAssertFalse(
            app.otherElements["ElementsGuidanceCard"].exists,
            "ElementsGuidanceCard must NOT exist when provider.guidance == nil"
        )
    }

    // MARK: - VoiceOver Focus Order (AC#14)

    /// T40: Y좌표 순서 — `ElementsSummaryCard` < `ElementRow_火` < `DisclaimerText`
    func testAccessibility_elementsAfterSummary() {
        launchAndPushElementsDetail()

        let summaryCard = app.otherElements["ElementsSummaryCard"]
        let firstRow = app.otherElements["ElementRow_火"]

        XCTAssertTrue(summaryCard.waitForExistence(timeout: 3))
        XCTAssertTrue(firstRow.waitForExistence(timeout: 3))
        // Summary card must appear above (smaller Y) than the first distribution row.
        XCTAssertLessThan(
            summaryCard.frame.maxY,
            firstRow.frame.minY,
            "Summary card must appear above distribution rows in the layout"
        )

        // Scroll down to bring disclaimer into view.
        app.scrollViews.firstMatch.swipeUp()
        let disclaimer = app.staticTexts["DisclaimerText"]
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 5),
                      "DisclaimerText must exist after scroll")

        // Disclaimer must appear below the first distribution row.
        // Use scrollView-relative coordinates (both must be on screen for this assertion to be valid).
        XCTAssertGreaterThan(
            disclaimer.frame.minY,
            firstRow.frame.maxY,
            "Disclaimer must appear below the distribution rows"
        )
    }

    // MARK: - Dynamic Type (AC#15)

    /// T41: contentSizeCategory XL → `GuidanceBullet_direction` 존재하고 레이블에 "…" 없음
    func testDynamicTypeXL_guidanceBulletVisible() {
        launchAndPushElementsDetail(
            extraEnv: ["UIContentSizeCategoryOverride": "UICTContentSizeCategoryXL"]
        )
        app.scrollViews.firstMatch.swipeUp()
        let bullet = app.otherElements["GuidanceBullet_direction"]
        XCTAssertTrue(bullet.waitForExistence(timeout: 5),
                      "GuidanceBullet_direction must exist at XL Dynamic Type")
        XCTAssertFalse(
            bullet.label.contains("…"),
            "Guidance bullet label must not be truncated at XL Dynamic Type"
        )
    }

    /// T42: contentSizeCategory XL → `ElementRow_火` 존재
    func testDynamicTypeXL_distributionRowVisible() {
        launchAndPushElementsDetail(
            extraEnv: ["UIContentSizeCategoryOverride": "UICTContentSizeCategoryXL"]
        )
        XCTAssertTrue(
            app.otherElements["ElementRow_火"].waitForExistence(timeout: 3),
            "ElementRow_火 must exist at XL Dynamic Type"
        )
    }
}
