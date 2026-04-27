import XCTest

/// UI tests for WF4-03 사주 탭 below-the-fold (사주 공부하기 섹션).
///
/// 모든 테스트는 `-resetOnboarding -openSajuTab`으로 앱을 실행하고,
/// `app.otherElements["SajuTabRoot"]` 존재 확인 후 스크롤로 below-fold 진입.
final class SajuBelowFoldUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

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

    /// ScrollView에서 below-fold까지 스크롤해 SajuStudySection을 화면에 올린다.
    private func scrollToBelowFold() {
        let scroll = app.scrollViews["SajuTabContent"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 5), "SajuTabContent scroll view must exist")
        // Scroll down twice to reach below-fold content
        scroll.swipeUp()
        scroll.swipeUp()
    }

    // TU-B01: study section exists below above-fold
    func test_studySection_exists_belowAboveFold() {
        launchSajuTab()
        scrollToBelowFold()
        XCTAssertTrue(
            app.otherElements["SajuStudySection"].waitForExistence(timeout: 5),
            "SajuStudySection must exist after scrolling below above-fold content"
        )
        // Above-fold elements must still be present in the scroll view
        XCTAssertTrue(app.otherElements["SajuOriginCard"].exists)
    }

    // TU-B02: streak badge visible with default mock (streakDays=3)
    func test_streakBadge_visibleWhenDefault() {
        launchSajuTab()
        scrollToBelowFold()
        let badge = app.staticTexts["SajuStreakBadge"]
        XCTAssertTrue(badge.waitForExistence(timeout: 5),
                      "SajuStreakBadge must exist with default mock (streakDays=3)")
        XCTAssertTrue(badge.label.contains("연속 3일"),
                      "Badge label should contain '연속 3일'")
    }

    // TU-B03: streak badge hidden when streakDays=0
    func test_streakBadge_hidden_when_streakDays0() {
        launchSajuTab(extraArgs: ["-sajuStreakDays", "0"])
        scrollToBelowFold()
        // Wait for study section to be visible
        XCTAssertTrue(
            app.otherElements["SajuStudySection"].waitForExistence(timeout: 5)
        )
        XCTAssertFalse(
            app.staticTexts["SajuStreakBadge"].exists,
            "SajuStreakBadge must not exist when streakDays=0"
        )
    }

    // TU-B04: all button tap pushes learn route
    func test_allButton_tap_pushesLearnRoute() {
        launchSajuTab()
        scrollToBelowFold()
        let allButton = app.buttons["SajuStudyAllButton"]
        XCTAssertTrue(allButton.waitForExistence(timeout: 5),
                      "SajuStudyAllButton must exist")
        allButton.tap()
        XCTAssertTrue(
            app.otherElements["SajuPlaceholderDestination_learn"].waitForExistence(timeout: 5),
            "Tapping '전체 ›' should push learn route"
        )
    }

    // TU-B05: featured lesson card exists with default mock
    func test_featuredLessonCard_exists_withDefaultMock() {
        launchSajuTab()
        scrollToBelowFold()
        let card = app.buttons["SajuFeaturedLessonCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 5),
                      "SajuFeaturedLessonCard must exist with default mock")
        XCTAssertTrue(card.label.contains("십성이란 무엇인가?"),
                      "Card label should contain '십성이란 무엇인가?'")
    }

    // TU-B06: featured lesson card label contains duration and level
    func test_featuredLessonCard_label_contains_3분_초급() {
        launchSajuTab()
        scrollToBelowFold()
        let card = app.buttons["SajuFeaturedLessonCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue(card.label.contains("3분"),
                      "Card label should contain '3분'")
        XCTAssertTrue(card.label.contains("초급"),
                      "Card label should contain '초급'")
    }

    // TU-B07: featured lesson card tap pushes lesson route with L-TEN-001
    func test_featuredLessonCard_tap_pushesLesson_LTEN001() {
        launchSajuTab()
        scrollToBelowFold()
        let card = app.buttons["SajuFeaturedLessonCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        let lessonDest = app.otherElements["SajuPlaceholderDestination_lesson"]
        XCTAssertTrue(lessonDest.waitForExistence(timeout: 5),
                      "SajuPlaceholderDestination_lesson should appear after tapping featured lesson")
        let idLabel = app.staticTexts["SajuPlaceholderDestination_lesson_Identifier"]
        XCTAssertTrue(idLabel.waitForExistence(timeout: 5))
        XCTAssertEqual(idLabel.label, "L-TEN-001")
    }

    // TU-B08: featured lesson card absent when featuredLesson=nil
    func test_featuredLessonCard_absent_whenLessonNil() {
        launchSajuTab(extraArgs: ["-sajuFeaturedLessonNil", "1"])
        scrollToBelowFold()
        XCTAssertTrue(
            app.otherElements["SajuStudySection"].waitForExistence(timeout: 5)
        )
        XCTAssertFalse(
            app.buttons["SajuFeaturedLessonCard"].exists,
            "SajuFeaturedLessonCard must not exist when featuredLesson=nil"
        )
        // Grid should still exist (right below header)
        XCTAssertTrue(
            app.otherElements["SajuCourseGrid"].exists,
            "SajuCourseGrid should exist even when featured lesson is nil"
        )
    }

    // TU-B09: four course cards exist
    func test_courseGrid_fourCardsExist() {
        launchSajuTab()
        scrollToBelowFold()
        let slots = ["입문", "오행", "십성", "대운"]
        for slot in slots {
            let card = app.buttons["SajuCourseCard_\(slot)"]
            XCTAssertTrue(card.waitForExistence(timeout: 5),
                          "SajuCourseCard_\(slot) must exist")
        }
    }

    // TU-B10: course grid order (입문 frame minY <= 오행 etc.)
    func test_courseGrid_order_fixed() {
        launchSajuTab()
        scrollToBelowFold()
        let intro  = app.buttons["SajuCourseCard_입문"]
        let ohang  = app.buttons["SajuCourseCard_오행"]
        let sipsung = app.buttons["SajuCourseCard_십성"]
        let daewoon = app.buttons["SajuCourseCard_대운"]

        XCTAssertTrue(intro.waitForExistence(timeout: 5))
        XCTAssertTrue(ohang.exists)
        XCTAssertTrue(sipsung.exists)
        XCTAssertTrue(daewoon.exists)

        // In a 2-column grid: 입문 (top-left) and 오행 (top-right) have same row;
        // 십성 and 대운 are in the second row.
        // 입문.minY <= 십성.minY, 오행.minY <= 대운.minY
        XCTAssertLessThanOrEqual(
            intro.frame.minY, sipsung.frame.minY,
            "입문 (row 0) should be above 십성 (row 1)"
        )
        XCTAssertLessThanOrEqual(
            ohang.frame.minY, daewoon.frame.minY,
            "오행 (row 0) should be above 대운 (row 1)"
        )
    }

    // TU-B11: intro course progress 100%
    func test_courseCard_introProgress_100percent() {
        launchSajuTab()
        scrollToBelowFold()
        let card = app.buttons["SajuCourseCard_입문"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue(card.label.contains("100%"),
                      "입문 card label should contain '100%'")
    }

    // TU-B12: 대운 course progress 0%
    func test_courseCard_daewoonProgress_0percent() {
        launchSajuTab()
        scrollToBelowFold()
        let card = app.buttons["SajuCourseCard_대운"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue(card.label.contains("0%"),
                      "대운 card label should contain '0%'")
    }

    // TU-B13: course card tap pushes learn route
    func test_courseCard_tap_pushesLearn() {
        launchSajuTab()
        scrollToBelowFold()
        let card = app.buttons["SajuCourseCard_입문"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        XCTAssertTrue(
            app.otherElements["SajuPlaceholderDestination_learn"].waitForExistence(timeout: 5),
            "Tapping a course card should push learn route"
        )
    }

    // TU-B14: glossary card subtitle 120개
    func test_glossaryCard_subtitle_120개() {
        launchSajuTab()
        scrollToBelowFold()
        let card = app.buttons["SajuGlossaryCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 5),
                      "SajuGlossaryCard must exist")
        XCTAssertTrue(card.label.contains("명리학 용어 120개"),
                      "Glossary card label should contain '명리학 용어 120개'")
    }

    // TU-B15: glossary card tap does not change navigation
    func test_glossaryCard_tap_noNavigation() {
        launchSajuTab()
        scrollToBelowFold()
        let card = app.buttons["SajuGlossaryCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        // SajuStudySection should still be present (no navigation occurred)
        XCTAssertTrue(
            app.otherElements["SajuStudySection"].waitForExistence(timeout: 3),
            "SajuStudySection should still be visible after tapping glossary card (no-op)"
        )
    }

    // TU-B16: disclaimer text visible
    func test_disclaimer_text_visible() {
        launchSajuTab()
        scrollToBelowFold()
        // Scroll extra to reach disclaimer at bottom
        app.scrollViews["SajuTabContent"].swipeUp()
        let disclaimer = app.staticTexts["DisclaimerText"]
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 5),
                      "DisclaimerText must exist at the bottom of saju study section")
        XCTAssertTrue(disclaimer.label.contains("본 앱은 학습·참고용이며"),
                      "Disclaimer should contain '본 앱은 학습·참고용이며'")
    }

    // TU-B17: tab bar active index 2
    func test_tabBar_active_index2() {
        launchSajuTab()
        let sajuTab = app.tabBars.buttons["사주 탭"]
        XCTAssertTrue(sajuTab.waitForExistence(timeout: 5),
                      "사주 탭 tab bar button must exist")
        XCTAssertTrue(sajuTab.isSelected,
                      "사주 탭 should be selected (active=2) after -openSajuTab launch")
    }

    // TU-B18: Dynamic Type XL — grid cards no truncation
    func test_dynamicType_xl_gridCards_noTruncation() {
        launchSajuTab(extraEnv: ["UIContentSizeCategoryOverride": "UICTContentSizeCategoryXL"])
        scrollToBelowFold()
        let slots = ["입문", "오행", "십성", "대운"]
        for slot in slots {
            let card = app.buttons["SajuCourseCard_\(slot)"]
            XCTAssertTrue(card.waitForExistence(timeout: 5),
                          "SajuCourseCard_\(slot) must exist at XL Dynamic Type")
            XCTAssertGreaterThan(card.frame.height, 44,
                                 "Card \(slot) height should be > 44 at XL Dynamic Type")
        }
    }

    // TU-B19: VoiceOver featured lesson card label
    func test_voiceOver_featuredLessonCard_accessibilityLabel() {
        launchSajuTab()
        scrollToBelowFold()
        let card = app.buttons["SajuFeaturedLessonCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        let expected = "오늘의 한 가지, 십성이란 무엇인가?, 3분, 초급"
        XCTAssertEqual(card.label, expected,
                       "Featured lesson card VoiceOver label should match '\(expected)'")
    }

    // TU-B20: hit target min height 44
    func test_hitTarget_allCards_minHeight44() {
        launchSajuTab()
        scrollToBelowFold()

        let featuredCard = app.buttons["SajuFeaturedLessonCard"]
        XCTAssertTrue(featuredCard.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(featuredCard.frame.height, 44)

        let glossaryCard = app.buttons["SajuGlossaryCard"]
        XCTAssertTrue(glossaryCard.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(glossaryCard.frame.height, 44)

        let slots = ["입문", "오행", "십성", "대운"]
        for slot in slots {
            let card = app.buttons["SajuCourseCard_\(slot)"]
            XCTAssertTrue(card.waitForExistence(timeout: 5),
                          "SajuCourseCard_\(slot) must exist")
            XCTAssertGreaterThanOrEqual(card.frame.height, 44,
                                        "Card \(slot) hit target height must be >= 44pt")
        }
    }

    // TU-B21: hit target min width 44
    func test_hitTarget_allCards_minWidth44() {
        launchSajuTab()
        scrollToBelowFold()

        let featuredCard = app.buttons["SajuFeaturedLessonCard"]
        XCTAssertTrue(featuredCard.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(featuredCard.frame.width, 44)

        let glossaryCard = app.buttons["SajuGlossaryCard"]
        XCTAssertTrue(glossaryCard.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(glossaryCard.frame.width, 44)

        let slots = ["입문", "오행", "십성", "대운"]
        for slot in slots {
            let card = app.buttons["SajuCourseCard_\(slot)"]
            XCTAssertTrue(card.waitForExistence(timeout: 5))
            XCTAssertGreaterThanOrEqual(card.frame.width, 44,
                                        "Card \(slot) hit target width must be >= 44pt")
        }
    }
}
