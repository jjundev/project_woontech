import XCTest

/// UI tests for WF4-06 사주 공부 리스트.
///
/// 공통 설정: `-resetOnboarding -openSajuTab` 실행 후
/// `SajuNavPush_learn` 버튼으로 `SajuLearnListView` 진입.
final class SajuLearnListUITests: XCTestCase {
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
            "SajuTabRoot must exist after launch"
        )
    }

    /// SajuLearnListView까지 진입한다.
    private func launchLearnList(extraArgs: [String] = [], extraEnv: [String: String] = [:]) {
        launchSajuTab(extraArgs: extraArgs, extraEnv: extraEnv)
        let btn = app.buttons["SajuNavPush_learn"]
        XCTAssertTrue(btn.waitForExistence(timeout: 3), "SajuNavPush_learn must exist")
        btn.tap()
        XCTAssertTrue(
            app.otherElements["SajuLearnListView"].waitForExistence(timeout: 5),
            "SajuLearnListView must appear"
        )
    }

    // MARK: - TU-L01 Navigate from below-fold "전체 ›"

    func test_navigate_fromBelowFold_allButton() {
        launchSajuTab()
        let scroll = app.scrollViews["SajuTabContent"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        scroll.swipeUp()
        scroll.swipeUp()
        let allBtn = app.buttons["SajuStudyHeaderAllButton"]
        XCTAssertTrue(allBtn.waitForExistence(timeout: 5))
        allBtn.tap()
        XCTAssertTrue(
            app.otherElements["SajuLearnListView"].waitForExistence(timeout: 5),
            "SajuLearnListView should appear after tapping 전체 › button"
        )
    }

    // MARK: - TU-L02 Navigate from course card

    func test_navigate_fromBelowFold_courseCard() {
        launchSajuTab()
        let scroll = app.scrollViews["SajuTabContent"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        scroll.swipeUp()
        scroll.swipeUp()
        let courseCard = app.buttons["SajuCourseCard_입문"]
        XCTAssertTrue(courseCard.waitForExistence(timeout: 5))
        courseCard.tap()
        XCTAssertTrue(
            app.otherElements["SajuLearnListView"].waitForExistence(timeout: 5),
            "SajuLearnListView should appear after tapping SajuCourseCard_입문"
        )
    }

    // MARK: - TU-L03 NavBar title

    func test_navBar_title_사주공부() {
        launchLearnList()
        XCTAssertTrue(app.navigationBars["사주 공부"].waitForExistence(timeout: 3))
    }

    // MARK: - TU-L04 NavBar search button exists

    func test_navBar_searchButton_exists() {
        launchLearnList()
        XCTAssertTrue(
            app.buttons["SajuLearnSearchButton"].waitForExistence(timeout: 3),
            "SajuLearnSearchButton must exist"
        )
    }

    // MARK: - TU-L05 NavBar search button tap is no-op

    func test_navBar_searchButton_tap_isNoOp() {
        launchLearnList()
        let searchBtn = app.buttons["SajuLearnSearchButton"]
        XCTAssertTrue(searchBtn.waitForExistence(timeout: 3))
        searchBtn.tap()
        XCTAssertTrue(
            app.otherElements["SajuLearnListView"].waitForExistence(timeout: 3),
            "SajuLearnListView should still be on screen after search tap (no push)"
        )
    }

    // MARK: - TU-L06 Category pills count = 6

    func test_categoryPills_count_is6() {
        launchLearnList()
        let pillIds = ["all", "intro", "elements", "tenGods", "daewoon", "hapchung"]
        for id in pillIds {
            XCTAssertTrue(
                app.buttons["SajuLearnCategoryPill_\(id)"].waitForExistence(timeout: 3),
                "SajuLearnCategoryPill_\(id) must exist"
            )
        }
    }

    // MARK: - TU-L07 Category pills order

    func test_categoryPills_order_fixed() {
        launchLearnList()
        let pillIds = ["all", "intro", "elements", "tenGods", "daewoon", "hapchung"]
        var prevMaxX: CGFloat = 0
        for id in pillIds {
            let pill = app.buttons["SajuLearnCategoryPill_\(id)"]
            XCTAssertTrue(pill.waitForExistence(timeout: 3))
            let minX = pill.frame.minX
            XCTAssertGreaterThan(minX, prevMaxX - 1,
                "Pill \(id) must be to the right of previous pill")
            prevMaxX = pill.frame.maxX
        }
    }

    // MARK: - TU-L08 Initial selection is "전체"

    func test_categoryPills_initialSelection_전체() {
        launchLearnList()
        let allPill = app.buttons["SajuLearnCategoryPill_all"]
        XCTAssertTrue(allPill.waitForExistence(timeout: 3))
        XCTAssertTrue(
            allPill.label.contains("선택됨"),
            "Initial pill 'all' must have '선택됨' in its accessibility label"
        )
    }

    // MARK: - TU-L09 Pill selection switch

    func test_categoryPills_switchSelection() {
        launchLearnList()
        let introPill = app.buttons["SajuLearnCategoryPill_intro"]
        XCTAssertTrue(introPill.waitForExistence(timeout: 3))
        introPill.tap()
        XCTAssertTrue(
            introPill.label.contains("선택됨"),
            "After tap, intro pill should be selected"
        )
        let allPill = app.buttons["SajuLearnCategoryPill_all"]
        XCTAssertTrue(allPill.waitForExistence(timeout: 3))
        XCTAssertTrue(
            allPill.label.contains("선택 안됨"),
            "After intro tap, all pill should be unselected"
        )
    }

    // MARK: - TU-L10 Weekly banner exists

    func test_weeklyBanner_exists() {
        launchLearnList()
        XCTAssertTrue(
            app.otherElements["SajuLearnWeeklyBanner"].waitForExistence(timeout: 3),
            "SajuLearnWeeklyBanner must exist"
        )
    }

    // MARK: - TU-L11 Streak badge visible (default)

    func test_weeklyBanner_streakBadge_visible_default() {
        launchLearnList()
        XCTAssertTrue(
            app.otherElements["SajuLearnWeeklyBanner"].waitForExistence(timeout: 3),
            "Weekly banner must exist"
        )
        // SajuLearnStreakBadge is a Text rendered inside the banner when streakDays > 0.
        // It may appear as staticText in the accessibility tree.
        let predicate = NSPredicate(format: "identifier == 'SajuLearnStreakBadge'")
        let badge = app.staticTexts.matching(predicate).firstMatch
        XCTAssertTrue(
            badge.waitForExistence(timeout: 3),
            "SajuLearnStreakBadge must be visible when streakDays=3"
        )
        XCTAssertTrue(
            badge.label.contains("연속 3일") || badge.label.contains("3일"),
            "Streak badge should mention '연속 3일'"
        )
    }

    // MARK: - TU-L12 Streak badge hidden when streakDays=0

    func test_weeklyBanner_streakBadge_hidden_streakDays0() {
        launchLearnList(extraArgs: ["-sajuLearnStreakZero"])
        XCTAssertTrue(app.otherElements["SajuLearnWeeklyBanner"].waitForExistence(timeout: 3))
        let badge = app.staticTexts.matching(NSPredicate(format: "identifier == 'SajuLearnStreakBadge'")).firstMatch
        XCTAssertFalse(badge.exists, "SajuLearnStreakBadge must not exist when streakDays=0")
    }

    // MARK: - TU-L13 Weekly banner completed/total text

    func test_weeklyBanner_completedTotalText() {
        launchLearnList()
        let label = app.staticTexts["3 / 5강 완료"]
        if !label.waitForExistence(timeout: 3) {
            // Check if it exists somewhere in the tree
            let predicate = NSPredicate(format: "label CONTAINS '3 / 5강 완료'")
            XCTAssertTrue(
                app.staticTexts.matching(predicate).firstMatch.waitForExistence(timeout: 3),
                "Text '3 / 5강 완료' must appear in the banner"
            )
        }
    }

    // MARK: - TU-L14 Course header text

    func test_courseHeader_text() {
        launchLearnList()
        let header = app.otherElements["SajuLearnCourseHeader"]
        XCTAssertTrue(header.waitForExistence(timeout: 3))
        XCTAssertTrue(header.label.contains("입문 코스"),
            "Course header must contain '입문 코스'")
        XCTAssertTrue(header.label.contains("7강"),
            "Course header must mention '7강'")
    }

    // MARK: - TU-L15 Course list 7 cards

    func test_courseList_7cards_exist() {
        launchLearnList()
        for i in 1...7 {
            let card = app.buttons["SajuLearnLessonCard_L\(i)"]
            XCTAssertTrue(
                card.waitForExistence(timeout: 3),
                "SajuLearnLessonCard_L\(i) must exist"
            )
        }
    }

    // MARK: - TU-L16 Completed card label contains "완료"

    func test_lessonCard_completed_accessibilityLabel() {
        launchLearnList()
        let card = app.buttons["SajuLearnLessonCard_L1"]
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        XCTAssertTrue(card.label.contains("완료"),
            "L1 card label must contain '완료'")
    }

    // MARK: - TU-L17 Current card label contains "이어보기"

    func test_lessonCard_current_continueLabel() {
        launchLearnList()
        let card = app.buttons["SajuLearnLessonCard_L4"]
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        XCTAssertTrue(card.label.contains("이어보기"),
            "L4 (current) card must mention '이어보기'")
    }

    // MARK: - TU-L18 Locked card label contains "잠김"

    func test_lessonCard_locked_label() {
        launchLearnList()
        let card = app.buttons["SajuLearnLessonCard_L5"]
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        XCTAssertTrue(card.label.contains("잠김"),
            "L5 (locked) card must mention '잠김'")
    }

    // MARK: - TU-L19 Completed card tap pushes lesson

    func test_lessonCard_completed_tap_pushesLesson() {
        launchLearnList()
        let card = app.buttons["SajuLearnLessonCard_L1"]
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        card.tap()
        // After push, lesson placeholder shows "L1" identifier
        let lessonDest = app.otherElements["SajuPlaceholderDestination_lesson"]
        XCTAssertTrue(lessonDest.waitForExistence(timeout: 5),
            "Lesson destination must appear after tapping L1")
    }

    // MARK: - TU-L20 Current card tap pushes lesson

    func test_lessonCard_current_tap_pushesLesson() {
        launchLearnList()
        let card = app.buttons["SajuLearnLessonCard_L4"]
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        card.tap()
        let lessonDest = app.otherElements["SajuPlaceholderDestination_lesson"]
        XCTAssertTrue(lessonDest.waitForExistence(timeout: 5),
            "Lesson destination must appear after tapping L4")
    }

    // MARK: - TU-L21 Locked card tap shows toast

    func test_lessonCard_locked_tap_showsToast() {
        launchLearnList()
        let card = app.buttons["SajuLearnLessonCard_L5"]
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        card.tap()
        XCTAssertTrue(
            app.otherElements["SajuLearnToast"].waitForExistence(timeout: 3),
            "Toast must appear after tapping locked L5"
        )
    }

    // MARK: - TU-L22 Locked card tap — path unchanged

    func test_lessonCard_locked_tap_pathUnchanged() {
        launchLearnList()
        let card = app.buttons["SajuLearnLessonCard_L5"]
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        card.tap()
        // SajuLearnListView should still be on screen (no push)
        XCTAssertTrue(
            app.otherElements["SajuLearnListView"].waitForExistence(timeout: 3),
            "SajuLearnListView must still be on screen after locked tap"
        )
    }

    // MARK: - TU-L23 Toast auto-dismisses after 2 seconds

    func test_toast_autoDismiss_after2sec() {
        launchLearnList()
        let card = app.buttons["SajuLearnLessonCard_L5"]
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        card.tap()
        XCTAssertTrue(app.otherElements["SajuLearnToast"].waitForExistence(timeout: 3))
        // Wait 3 seconds for auto-dismiss
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: app.otherElements["SajuLearnToast"]
        )
        wait(for: [expectation], timeout: 5)
    }

    // MARK: - TU-L24 Article section visible (default)

    func test_articleSection_visible_default() {
        launchLearnList()
        // Scroll down to reach article section
        app.swipeUp()
        XCTAssertTrue(
            app.otherElements["SajuLearnArticleSection"].waitForExistence(timeout: 5),
            "SajuLearnArticleSection must exist with default provider"
        )
    }

    // MARK: - TU-L25 Article section 2 cards

    func test_articleSection_2cards() {
        launchLearnList()
        app.swipeUp()
        XCTAssertTrue(app.buttons["SajuLearnArticleCard_A1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["SajuLearnArticleCard_A2"].waitForExistence(timeout: 5))
    }

    // MARK: - TU-L26 Article section hidden when empty

    func test_articleSection_hidden_whenEmpty() {
        launchLearnList(extraArgs: ["-sajuLearnArticlesEmpty"])
        app.swipeUp()
        // Give a moment for any potential appearance
        let section = app.otherElements["SajuLearnArticleSection"]
        let exists = section.waitForExistence(timeout: 3)
        XCTAssertFalse(exists, "SajuLearnArticleSection must not exist when articles are empty")
    }

    // MARK: - TU-L27 Article card tap no navigation

    func test_articleCard_tap_noNavigation() {
        launchLearnList()
        app.swipeUp()
        let card = app.buttons["SajuLearnArticleCard_A1"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        XCTAssertTrue(
            app.otherElements["SajuLearnListView"].waitForExistence(timeout: 3),
            "SajuLearnListView must remain on screen after article tap"
        )
    }

    // MARK: - TU-L28 Pill hit targets ≥ 44

    func test_hitTarget_pills_minSize44() {
        launchLearnList()
        let pillIds = ["all", "intro", "elements", "tenGods", "daewoon", "hapchung"]
        for id in pillIds {
            let pill = app.buttons["SajuLearnCategoryPill_\(id)"]
            XCTAssertTrue(pill.waitForExistence(timeout: 3))
            XCTAssertGreaterThanOrEqual(
                pill.frame.height, 44,
                "Pill \(id) hit target must be ≥ 44pt"
            )
        }
    }

    // MARK: - TU-L29 Lesson card hit targets ≥ 44

    func test_hitTarget_lessonCards_minSize44() {
        launchLearnList()
        for i in 1...7 {
            let card = app.buttons["SajuLearnLessonCard_L\(i)"]
            XCTAssertTrue(card.waitForExistence(timeout: 3))
            XCTAssertGreaterThanOrEqual(
                card.frame.height, 44,
                "Lesson card L\(i) hit target must be ≥ 44pt"
            )
        }
    }

    // MARK: - TU-L30 Article card hit targets ≥ 44

    func test_hitTarget_articleCards_minSize44() {
        launchLearnList()
        app.swipeUp()
        for id in ["A1", "A2"] {
            let card = app.buttons["SajuLearnArticleCard_\(id)"]
            XCTAssertTrue(card.waitForExistence(timeout: 5))
            XCTAssertGreaterThanOrEqual(
                card.frame.height, 44,
                "Article card \(id) hit target must be ≥ 44pt"
            )
        }
    }

    // MARK: - TU-L31 Dynamic Type XL lesson cards no truncation

    func test_dynamicType_xl_lessonCards_noTruncation() {
        launchLearnList(extraEnv: ["UIContentSizeCategoryOverride": "UICTContentSizeCategoryXL"])
        let card = app.buttons["SajuLearnLessonCard_L1"]
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        XCTAssertGreaterThan(card.frame.height, 44,
            "At XL Dynamic Type, lesson card should be taller than 44pt to accommodate larger text")
    }
}
