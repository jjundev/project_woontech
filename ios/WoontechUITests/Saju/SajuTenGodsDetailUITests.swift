import XCTest

/// UI tests for WF4-05 십성 분석 상세 (`SajuTenGodsDetailView`).
///
/// 모든 테스트는 `-resetOnboarding -openSajuTab`으로 앱을 실행하고
/// `SajuNavPush_tenGods` 히든 트리거를 탭해 `SajuTenGodsDetailView`로 진입한다.
final class SajuTenGodsDetailUITests: XCTestCase {
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

    /// `SajuTenGodsDetailView`로 push한다.
    private func launchAndPushTenGodsDetail(
        extraArgs: [String] = [],
        extraEnv: [String: String] = [:]
    ) {
        launchSajuTab(extraArgs: extraArgs, extraEnv: extraEnv)
        let btn = app.buttons["SajuNavPush_tenGods"]
        XCTAssertTrue(btn.waitForExistence(timeout: 3),
                      "SajuNavPush_tenGods trigger button must exist")
        btn.tap()
        XCTAssertTrue(
            app.otherElements["SajuTenGodsDetailView"].waitForExistence(timeout: 5),
            "SajuTenGodsDetailView must appear after tapping SajuNavPush_tenGods"
        )
    }

    // MARK: - 6.1 Navigation (AC#1, AC#2)

    /// T31: `SajuNavPush_tenGods` 탭 → `SajuTenGodsDetailView` 존재
    func testNavPush_tenGods_showsDetailView() {
        launchSajuTab()
        let btn = app.buttons["SajuNavPush_tenGods"]
        XCTAssertTrue(btn.waitForExistence(timeout: 3))
        btn.tap()
        XCTAssertTrue(
            app.otherElements["SajuTenGodsDetailView"].waitForExistence(timeout: 5),
            "SajuTenGodsDetailView should appear after pushing .tenGods route"
        )
    }

    /// T32: NavBar 타이틀 "십성 분석"
    func testNavBarTitle_is십성분석() {
        launchAndPushTenGodsDetail()
        XCTAssertTrue(
            app.navigationBars.staticTexts["십성 분석"].waitForExistence(timeout: 3),
            "Navigation bar title should read '십성 분석'"
        )
    }

    /// T33: Back 탭 → `SajuTabRoot` visible
    func testBackButton_popsToSajuHome() {
        launchAndPushTenGodsDetail()
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 3),
                      "System back button must exist in navigation bar")
        backButton.tap()
        XCTAssertTrue(
            app.otherElements["SajuTabRoot"].waitForExistence(timeout: 3),
            "SajuTabRoot should be visible after tapping back"
        )
    }

    // MARK: - 6.2 요약 카드 (AC#3)

    /// T34: `TenGodsSummaryHeadline` 존재 + label 비어있지 않음
    func testSummaryCard_headlineVisible() {
        launchAndPushTenGodsDetail()
        let headline = app.staticTexts["TenGodsSummaryHeadline"]
        XCTAssertTrue(headline.waitForExistence(timeout: 3),
                      "TenGodsSummaryHeadline must be visible")
        XCTAssertFalse(headline.label.isEmpty,
                       "TenGodsSummaryHeadline label must not be empty")
    }

    /// T35: `TenGodsSummaryBody` 존재
    func testSummaryCard_bodyVisible() {
        launchAndPushTenGodsDetail()
        XCTAssertTrue(
            app.staticTexts["TenGodsSummaryBody"].waitForExistence(timeout: 3),
            "TenGodsSummaryBody must be visible"
        )
    }

    /// T36: `TenGodsSummaryHeadline` label == "정재가 중심인 사주"
    func testSummaryCard_headlineMatchesMock() {
        launchAndPushTenGodsDetail()
        let headline = app.staticTexts["TenGodsSummaryHeadline"]
        XCTAssertTrue(headline.waitForExistence(timeout: 3))
        XCTAssertEqual(headline.label, "정재가 중심인 사주",
                       "Headline must match MockSajuTenGodsDetailProvider default")
    }

    // MARK: - 6.3 5그룹 분포 (AC#4–8)

    /// T37: `TenGodsGroupRow_비겁` ~ `TenGodsGroupRow_인성` 5개 존재
    func testDistribution_fiveGroupRowsExist() {
        launchAndPushTenGodsDetail()
        let names = ["비겁", "식상", "재성", "관성", "인성"]
        for name in names {
            XCTAssertTrue(
                app.otherElements["TenGodsGroupRow_\(name)"].waitForExistence(timeout: 3),
                "TenGodsGroupRow_\(name) must exist"
            )
        }
    }

    /// T38: Y좌표 순서 — 비겁 < 식상 < 재성 < 관성 < 인성
    func testDistribution_orderIsSpec() {
        launchAndPushTenGodsDetail()
        let names = ["비겁", "식상", "재성", "관성", "인성"]
        var prevMaxY: CGFloat = -1
        for name in names {
            let row = app.otherElements["TenGodsGroupRow_\(name)"]
            XCTAssertTrue(row.waitForExistence(timeout: 3),
                          "TenGodsGroupRow_\(name) must exist for Y-order check")
            XCTAssertGreaterThan(row.frame.minY, prevMaxY,
                                 "TenGodsGroupRow_\(name) must appear below the previous row")
            prevMaxY = row.frame.maxY
        }
    }

    /// T39: `TenGodsGroupRow_재성` label에 "핵심" 포함 (isCore=true)
    func testDistribution_재성_hasCoreBadge() {
        launchAndPushTenGodsDetail()
        let coreRow = app.otherElements["TenGodsGroupRow_재성"]
        XCTAssertTrue(coreRow.waitForExistence(timeout: 3),
                      "TenGodsGroupRow_재성 must exist")
        XCTAssertTrue(
            coreRow.label.contains("핵심"),
            "TenGodsGroupRow_재성 accessibility label must contain '핵심'; got: '\(coreRow.label)'"
        )
    }

    /// T40: `TenGodsGroupRow_식상` label에 "부재" 포함 (isAbsent=true)
    func testDistribution_식상_isAbsent_accessibilityLabel() {
        launchAndPushTenGodsDetail()
        let absentRow = app.otherElements["TenGodsGroupRow_식상"]
        XCTAssertTrue(absentRow.waitForExistence(timeout: 3),
                      "TenGodsGroupRow_식상 must exist")
        XCTAssertTrue(
            absentRow.label.contains("부재"),
            "TenGodsGroupRow_식상 accessibility label must contain '부재'; got: '\(absentRow.label)'"
        )
    }

    /// T41: `TenGodsDisplayedItems_비겁` label == "비견" (counts=[1,0])
    func testDistribution_비겁_displayedItems() {
        launchAndPushTenGodsDetail()
        let displayedItems = app.staticTexts["TenGodsDisplayedItems_비겁"]
        XCTAssertTrue(displayedItems.waitForExistence(timeout: 3),
                      "TenGodsDisplayedItems_비겁 must exist")
        XCTAssertEqual(displayedItems.label, "비견",
                       "비겁 displayedItems must be '비견' (counts=[1,0])")
    }

    /// T42: `TenGodsDisplayedItems_식상` label == "—" (counts=[0,0])
    func testDistribution_식상_displayedItemsIsEmpty() {
        launchAndPushTenGodsDetail()
        let displayedItems = app.staticTexts["TenGodsDisplayedItems_식상"]
        XCTAssertTrue(displayedItems.waitForExistence(timeout: 3),
                      "TenGodsDisplayedItems_식상 must exist")
        XCTAssertEqual(displayedItems.label, "—",
                       "식상 displayedItems must be '—' (all counts zero)")
    }

    // MARK: - 6.4 핵심 십성 카드 (AC#10, AC#11)

    /// T43: `TenGodsCoreCard_0`, `_1`, `_2` 존재
    func testCoreSection_threeCardsExist() {
        launchAndPushTenGodsDetail()
        for index in 0...2 {
            XCTAssertTrue(
                app.otherElements["TenGodsCoreCard_\(index)"].waitForExistence(timeout: 3),
                "TenGodsCoreCard_\(index) must exist"
            )
        }
    }

    /// T44: `TenGodsCoreCard_0` label에 "정재" 포함
    func testCoreSection_firstCard_containsProvider() {
        launchAndPushTenGodsDetail()
        let firstCard = app.otherElements["TenGodsCoreCard_0"]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 3),
                      "TenGodsCoreCard_0 must exist")
        XCTAssertTrue(
            firstCard.label.contains("정재"),
            "TenGodsCoreCard_0 label must contain '정재'; got: '\(firstCard.label)'"
        )
    }

    /// T45: `TenGodsCoreCard_0` 표시 확인 (frame.height > 0); 시각 배경 구분은 코드리뷰
    func testCoreSection_firstCard_differentBg() {
        launchAndPushTenGodsDetail()
        let firstCard = app.otherElements["TenGodsCoreCard_0"]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 3),
                      "TenGodsCoreCard_0 must exist and be visible")
        XCTAssertGreaterThan(firstCard.frame.height, 0,
                             "TenGodsCoreCard_0 must have positive height (visible)")
    }

    // MARK: - 6.5 부재 경고 카드 (AC#12, AC#13)

    /// T46: 스크롤 후 `TenGodsAbsentWarningCard` 존재
    func testAbsentWarning_visibleByDefault() {
        launchAndPushTenGodsDetail()
        app.scrollViews.firstMatch.swipeUp()
        XCTAssertTrue(
            app.otherElements["TenGodsAbsentWarningCard"].waitForExistence(timeout: 5),
            "TenGodsAbsentWarningCard must exist with default mock"
        )
    }

    /// T47: `TenGodsAbsentWarningCard` label에 "주의" 포함
    func testAbsentWarning_accessibilityLabel_contains주의() {
        launchAndPushTenGodsDetail()
        app.scrollViews.firstMatch.swipeUp()
        let card = app.otherElements["TenGodsAbsentWarningCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 5),
                      "TenGodsAbsentWarningCard must exist")
        XCTAssertTrue(
            card.label.contains("주의"),
            "TenGodsAbsentWarningCard label must contain '주의'; got: '\(card.label)'"
        )
    }

    /// T48: `-sajuTenGodsNoAbsentWarning` → `TenGodsAbsentWarningCard` NOT exist
    func testAbsentWarning_hiddenWhenNil() {
        launchAndPushTenGodsDetail(extraArgs: ["-sajuTenGodsNoAbsentWarning"])
        app.scrollViews.firstMatch.swipeUp()
        // Give the UI a moment to settle before asserting absence.
        let _ = app.staticTexts["DisclaimerText"].waitForExistence(timeout: 5)
        XCTAssertFalse(
            app.otherElements["TenGodsAbsentWarningCard"].exists,
            "TenGodsAbsentWarningCard must NOT exist when absentWarning == nil"
        )
    }

    // MARK: - 6.6 학습 유도 카드 (AC#14, AC#15)

    /// T49: 스크롤 후 `TenGodsLearnEntryCard` 존재
    func testLearnEntry_visibleByDefault() {
        launchAndPushTenGodsDetail()
        app.scrollViews.firstMatch.swipeUp()
        XCTAssertTrue(
            app.buttons["TenGodsLearnEntryCard"].waitForExistence(timeout: 5),
            "TenGodsLearnEntryCard must exist with default mock"
        )
    }

    /// T50: `TenGodsLearnEntryCard` 탭 → `SajuPlaceholderDestination_lesson` + "L-TEN-001"
    func testLearnEntry_tap_pushesLessonRoute() {
        launchAndPushTenGodsDetail()
        let scroll = app.scrollViews["SajuTenGodsDetailScroll"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 5), "SajuTenGodsDetailScroll must exist")
        let learnCard = app.buttons["TenGodsLearnEntryCard"]
        XCTAssertTrue(learnCard.waitForExistence(timeout: 5),
                      "TenGodsLearnEntryCard must exist")
        // Scroll until the button is hittable (the learn card sits below a tall
        // distribution + core-cards section; 2 fixed swipes proved insufficient).
        for _ in 0..<6 {
            if learnCard.isHittable { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(learnCard.isHittable,
                      "TenGodsLearnEntryCard must be hittable after scrolling")
        learnCard.tap()
        XCTAssertTrue(
            app.otherElements["SajuPlaceholderDestination_lesson"].waitForExistence(timeout: 5),
            "SajuPlaceholderDestination_lesson must appear after tapping learn entry"
        )
        XCTAssertTrue(
            app.staticTexts["SajuPlaceholderDestination_lesson_Identifier"].waitForExistence(timeout: 3),
            "Lesson identifier element must exist"
        )
        XCTAssertEqual(
            app.staticTexts["SajuPlaceholderDestination_lesson_Identifier"].label,
            "L-TEN-001",
            "Lesson ID must be 'L-TEN-001'"
        )
    }

    /// T51: `-sajuTenGodsNoLearnEntry` → `TenGodsLearnEntryCard` NOT exist
    func testLearnEntry_hiddenWhenNil() {
        launchAndPushTenGodsDetail(extraArgs: ["-sajuTenGodsNoLearnEntry"])
        app.scrollViews.firstMatch.swipeUp()
        let _ = app.staticTexts["DisclaimerText"].waitForExistence(timeout: 5)
        XCTAssertFalse(
            app.buttons["TenGodsLearnEntryCard"].exists,
            "TenGodsLearnEntryCard must NOT exist when learnEntry == nil"
        )
    }

    // MARK: - 6.7 Disclaimer (AC#16)

    /// T52: swipeUp 후 `DisclaimerText` 존재 + "학습·참고용" 포함
    func testDisclaimer_existsAfterScroll() {
        launchAndPushTenGodsDetail()
        app.scrollViews.firstMatch.swipeUp()
        let disclaimer = app.staticTexts["DisclaimerText"]
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 5),
                      "DisclaimerText must exist in SajuTenGodsDetailView")
        XCTAssertTrue(
            disclaimer.label.contains("학습·참고용"),
            "Disclaimer must contain '학습·참고용'; got: '\(disclaimer.label)'"
        )
    }

    // MARK: - 6.8 VoiceOver 포커스 순서 (AC#18)

    /// T53: `TenGodsSummaryCard`.maxY < `TenGodsGroupRow_비겁`.minY
    func testA11yOrder_summaryBeforeDistribution() {
        launchAndPushTenGodsDetail()
        let summaryCard = app.otherElements["TenGodsSummaryCard"]
        let firstRow = app.otherElements["TenGodsGroupRow_비겁"]
        XCTAssertTrue(summaryCard.waitForExistence(timeout: 3))
        XCTAssertTrue(firstRow.waitForExistence(timeout: 3))
        XCTAssertLessThan(
            summaryCard.frame.maxY,
            firstRow.frame.minY,
            "TenGodsSummaryCard must appear above TenGodsGroupRow_비겁"
        )
    }

    /// T54: `TenGodsGroupRow_인성`.maxY < `TenGodsCoreCard_0`.minY
    func testA11yOrder_distributionBeforeCore() {
        launchAndPushTenGodsDetail()
        let lastRow = app.otherElements["TenGodsGroupRow_인성"]
        let firstCoreCard = app.otherElements["TenGodsCoreCard_0"]
        XCTAssertTrue(lastRow.waitForExistence(timeout: 3))
        XCTAssertTrue(firstCoreCard.waitForExistence(timeout: 3))
        XCTAssertLessThan(
            lastRow.frame.maxY,
            firstCoreCard.frame.minY,
            "TenGodsGroupRow_인성 must appear above TenGodsCoreCard_0"
        )
    }

    /// T57: `TenGodsCoreCard_2`.maxY < `TenGodsAbsentWarningCard`.minY
    func testA11yOrder_coreBeforeAbsentWarning() {
        launchAndPushTenGodsDetail()
        app.scrollViews.firstMatch.swipeUp()
        let lastCoreCard = app.otherElements["TenGodsCoreCard_2"]
        let warningCard = app.otherElements["TenGodsAbsentWarningCard"]
        XCTAssertTrue(lastCoreCard.waitForExistence(timeout: 3))
        XCTAssertTrue(warningCard.waitForExistence(timeout: 5))
        XCTAssertLessThan(
            lastCoreCard.frame.maxY,
            warningCard.frame.minY,
            "TenGodsCoreCard_2 must appear above TenGodsAbsentWarningCard"
        )
    }

    /// T58: `TenGodsAbsentWarningCard`.maxY < `TenGodsLearnEntryCard`.minY
    func testA11yOrder_absentWarningBeforeLearnEntry() {
        launchAndPushTenGodsDetail()
        app.scrollViews.firstMatch.swipeUp()
        let warningCard = app.otherElements["TenGodsAbsentWarningCard"]
        let learnCard = app.buttons["TenGodsLearnEntryCard"]
        XCTAssertTrue(warningCard.waitForExistence(timeout: 5))
        XCTAssertTrue(learnCard.waitForExistence(timeout: 5))
        XCTAssertLessThan(
            warningCard.frame.maxY,
            learnCard.frame.minY,
            "TenGodsAbsentWarningCard must appear above TenGodsLearnEntryCard"
        )
    }

    /// T59: `TenGodsLearnEntryCard`.maxY < `DisclaimerText`.minY
    func testA11yOrder_learnEntryBeforeDisclaimer() {
        launchAndPushTenGodsDetail()
        app.scrollViews.firstMatch.swipeUp()
        let learnCard = app.buttons["TenGodsLearnEntryCard"]
        let disclaimer = app.staticTexts["DisclaimerText"]
        XCTAssertTrue(learnCard.waitForExistence(timeout: 5))
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 5))
        XCTAssertLessThan(
            learnCard.frame.maxY,
            disclaimer.frame.minY,
            "TenGodsLearnEntryCard must appear above DisclaimerText"
        )
    }

    // MARK: - 6.9 Dynamic Type (AC#19)

    /// T55: XL Dynamic Type → `TenGodsInvestImplication_0` label에 "…" 미포함
    func testDynamicTypeXL_investImplicationNotTruncated() {
        launchAndPushTenGodsDetail(
            extraEnv: ["UIContentSizeCategoryOverride": "UICTContentSizeCategoryXL"]
        )
        let implEl = app.staticTexts["TenGodsInvestImplication_0"]
        XCTAssertTrue(implEl.waitForExistence(timeout: 3),
                      "TenGodsInvestImplication_0 must exist at XL Dynamic Type")
        XCTAssertFalse(
            implEl.label.contains("…"),
            "TenGodsInvestImplication_0 label must not be truncated at XL Dynamic Type"
        )
    }

    /// T56: XL Dynamic Type → `TenGodsAbsentWarningCopy` label에 "…" 미포함
    func testDynamicTypeXL_absentWarnCopyNotTruncated() {
        launchAndPushTenGodsDetail(
            extraEnv: ["UIContentSizeCategoryOverride": "UICTContentSizeCategoryXL"]
        )
        app.scrollViews.firstMatch.swipeUp()
        let copyEl = app.staticTexts["TenGodsAbsentWarningCopy"]
        XCTAssertTrue(copyEl.waitForExistence(timeout: 5),
                      "TenGodsAbsentWarningCopy must exist at XL Dynamic Type")
        XCTAssertFalse(
            copyEl.label.contains("…"),
            "TenGodsAbsentWarningCopy must not be truncated at XL Dynamic Type"
        )
    }
}
