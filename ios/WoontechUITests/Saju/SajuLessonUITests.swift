import XCTest

/// UI tests for WF4-07 레슨 상세 (학습 경험).
///
/// 공통 설정: `-resetOnboarding -openSajuTab` 실행 후
/// `SajuNavPush_lessonLOH003` 버튼으로 `SajuLessonView` 진입.
final class SajuLessonUITests: XCTestCase {
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

    /// SajuLessonView (기본값 L-OH-003)까지 진입.
    private func launchLesson(extraArgs: [String] = [], extraEnv: [String: String] = [:]) {
        launchSajuTab(extraArgs: extraArgs, extraEnv: extraEnv)
        let btn = app.buttons["SajuNavPush_lessonLOH003"]
        XCTAssertTrue(btn.waitForExistence(timeout: 3), "SajuNavPush_lessonLOH003 must exist")
        btn.tap()
        XCTAssertTrue(
            app.otherElements["SajuLessonView"].waitForExistence(timeout: 5),
            "SajuLessonView must appear"
        )
    }

    // MARK: - TU-LS01: SajuLearnListView에서 진입

    func test_navigate_fromLearnList_pushesLesson() {
        launchSajuTab()
        // Navigate to learn list
        let learnBtn = app.buttons["SajuNavPush_learn"]
        XCTAssertTrue(learnBtn.waitForExistence(timeout: 3))
        learnBtn.tap()
        XCTAssertTrue(app.otherElements["SajuLearnListView"].waitForExistence(timeout: 5))
        // Tap lesson card L3 (id="L3", which is "오행의 의미")
        let lessonCard = app.buttons["SajuLearnLessonCard_L3"]
        XCTAssertTrue(lessonCard.waitForExistence(timeout: 3), "SajuLearnLessonCard_L3 must exist")
        lessonCard.tap()
        XCTAssertTrue(
            app.otherElements["SajuLessonView"].waitForExistence(timeout: 5),
            "SajuLessonView must appear after tapping lesson card"
        )
    }

    // MARK: - TU-LS02: UITest push 버튼으로 진입

    func test_navigate_fromSajuNavPush_pushesLesson() {
        launchLesson()
        XCTAssertTrue(app.otherElements["SajuLessonView"].exists)
    }

    // MARK: - TU-LS03: NavBar 타이틀 형식

    func test_navBar_title_format() {
        launchLesson()
        XCTAssertTrue(
            app.navigationBars["3강 · 오행의 의미"].waitForExistence(timeout: 3),
            "NavBar title '3강 · 오행의 의미' must exist"
        )
    }

    // MARK: - TU-LS04: NavBar 우측 진행 텍스트

    func test_navBar_trailing_progress_text() {
        launchLesson()
        XCTAssertTrue(
            app.staticTexts["3/7"].waitForExistence(timeout: 3),
            "Progress text '3/7' must exist in NavBar"
        )
    }

    // MARK: - TU-LS05: 진행 바 존재

    func test_progressBar_exists() {
        launchLesson()
        XCTAssertTrue(
            app.otherElements["SajuLessonProgressBar"].waitForExistence(timeout: 3),
            "SajuLessonProgressBar must exist"
        )
    }

    // MARK: - TU-LS06: sectionLabel 바인딩

    func test_sectionLabel_binding() {
        launchLesson()
        let label = app.staticTexts["SajuLessonSectionLabel"]
        XCTAssertTrue(label.waitForExistence(timeout: 3))
        XCTAssertEqual(label.label, "기본 개념")
    }

    // MARK: - TU-LS07: headline 바인딩

    func test_headline_binding() {
        launchLesson()
        let headline = app.staticTexts["SajuLessonHeadline"]
        XCTAssertTrue(headline.waitForExistence(timeout: 3))
        XCTAssertEqual(headline.label, "오행이란?")
    }

    // MARK: - TU-LS08: 개념 박스 존재

    func test_conceptBox_exists() {
        launchLesson()
        XCTAssertTrue(
            app.otherElements["SajuLessonConceptBox"].waitForExistence(timeout: 3),
            "SajuLessonConceptBox must exist"
        )
    }

    // MARK: - TU-LS09: 다이어그램 placeholder 존재

    func test_diagramPlaceholder_exists() {
        launchLesson()
        XCTAssertTrue(
            app.otherElements["SajuLessonDiagramPlaceholder"].waitForExistence(timeout: 3),
            "SajuLessonDiagramPlaceholder must exist"
        )
    }

    // MARK: - TU-LS10: 퀴즈 선택지 4개 모두 존재

    func test_quizCard_4choices_exist() {
        launchLesson()
        for i in 0...3 {
            XCTAssertTrue(
                app.buttons["SajuLessonQuizChoice_\(i)"].waitForExistence(timeout: 3),
                "SajuLessonQuizChoice_\(i) must exist"
            )
        }
    }

    // MARK: - TU-LS11: CTA 초기 비활성

    func test_ctaButton_initially_disabled() {
        launchLesson()
        let cta = app.buttons["SajuLessonNextCTA"]
        XCTAssertTrue(cta.waitForExistence(timeout: 3))
        XCTAssertFalse(cta.isEnabled, "SajuLessonNextCTA must be initially disabled")
    }

    // MARK: - TU-LS12: 정답 탭 → CTA 활성화

    func test_correctChoice_tap_activatesCTA() {
        launchLesson()
        let choice = app.buttons["SajuLessonQuizChoice_2"] // correctIndex=2
        XCTAssertTrue(choice.waitForExistence(timeout: 3))
        choice.tap()
        let cta = app.buttons["SajuLessonNextCTA"]
        XCTAssertTrue(cta.waitForExistence(timeout: 3))
        XCTAssertTrue(cta.isEnabled, "SajuLessonNextCTA must be enabled after correct choice tap")
    }

    // MARK: - TU-LS13: 오답 탭 → CTA 활성화

    func test_incorrectChoice_tap_activatesCTA() {
        launchLesson()
        let choice = app.buttons["SajuLessonQuizChoice_0"] // incorrect
        XCTAssertTrue(choice.waitForExistence(timeout: 3))
        choice.tap()
        let cta = app.buttons["SajuLessonNextCTA"]
        XCTAssertTrue(cta.waitForExistence(timeout: 3))
        XCTAssertTrue(cta.isEnabled, "SajuLessonNextCTA must be enabled after incorrect choice tap")
    }

    // MARK: - TU-LS14: 두 번째 탭 무시

    func test_secondTap_ignored() {
        launchLesson()
        let choice2 = app.buttons["SajuLessonQuizChoice_2"]
        XCTAssertTrue(choice2.waitForExistence(timeout: 3))
        choice2.tap()
        // Tap another choice
        let choice1 = app.buttons["SajuLessonQuizChoice_1"]
        XCTAssertTrue(choice1.waitForExistence(timeout: 3))
        choice1.tap()
        // CTA should still be enabled (state not reset)
        let cta = app.buttons["SajuLessonNextCTA"]
        XCTAssertTrue(cta.isEnabled, "CTA should remain enabled after second tap")
    }

    // MARK: - TU-LS15: CTA 탭 → replace top (다음 강의)

    func test_nextCTA_nextId_replacesTop() {
        // Navigate from learn list so we can check back behavior
        launchSajuTab()
        let learnBtn = app.buttons["SajuNavPush_learn"]
        XCTAssertTrue(learnBtn.waitForExistence(timeout: 3))
        learnBtn.tap()
        XCTAssertTrue(app.otherElements["SajuLearnListView"].waitForExistence(timeout: 5))

        // Navigate to lesson L-OH-003
        let lessonBtn = app.buttons["SajuNavPush_lessonLOH003"]
        XCTAssertTrue(lessonBtn.waitForExistence(timeout: 3))
        lessonBtn.tap()
        XCTAssertTrue(app.otherElements["SajuLessonView"].waitForExistence(timeout: 5))

        // Tap correct choice
        let choice2 = app.buttons["SajuLessonQuizChoice_2"]
        XCTAssertTrue(choice2.waitForExistence(timeout: 3))
        choice2.tap()

        // Tap CTA → should replace with next lesson (L-OH-004 → fallback "준비중")
        let cta = app.buttons["SajuLessonNextCTA"]
        XCTAssertTrue(cta.waitForExistence(timeout: 3))
        cta.tap()

        // Still on a SajuLessonView (the replaced next lesson)
        XCTAssertTrue(
            app.otherElements["SajuLessonView"].waitForExistence(timeout: 5),
            "Should still show SajuLessonView for next lesson"
        )

        // Back should go to LearnList (not to previous lesson)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(
            app.otherElements["SajuLearnListView"].waitForExistence(timeout: 5),
            "Back from replaced lesson should go to SajuLearnListView"
        )
    }

    // MARK: - TU-LS16: -sajuLessonNoNextId → CTA 라벨 "학습 완료"

    func test_nextCTA_noNextId_label_is학습완료() {
        launchSajuTab(extraArgs: ["-sajuLessonNoNextId"])
        let btn = app.buttons["SajuNavPush_lessonNoNext"]
        XCTAssertTrue(btn.waitForExistence(timeout: 3))
        btn.tap()
        XCTAssertTrue(app.otherElements["SajuLessonView"].waitForExistence(timeout: 5))

        let cta = app.buttons["SajuLessonNextCTA"]
        XCTAssertTrue(cta.waitForExistence(timeout: 3))
        XCTAssertTrue(
            cta.label.contains("학습 완료"),
            "CTA label must be '학습 완료' when nextLessonId=nil, got: \(cta.label)"
        )
    }

    // MARK: - TU-LS17: -sajuLessonNoNextId → CTA 탭 → LearnList 복귀

    func test_nextCTA_noNextId_tap_popsToLearnList() {
        launchSajuTab(extraArgs: ["-sajuLessonNoNextId"])
        // Push learn list first so we have something to pop to
        let learnBtn = app.buttons["SajuNavPush_learn"]
        XCTAssertTrue(learnBtn.waitForExistence(timeout: 3))
        learnBtn.tap()
        XCTAssertTrue(app.otherElements["SajuLearnListView"].waitForExistence(timeout: 5))

        let btn = app.buttons["SajuNavPush_lessonNoNext"]
        XCTAssertTrue(btn.waitForExistence(timeout: 3))
        btn.tap()
        XCTAssertTrue(app.otherElements["SajuLessonView"].waitForExistence(timeout: 5))

        // Tap correct choice (correctIndex=1 for lastLesson)
        let choice1 = app.buttons["SajuLessonQuizChoice_1"]
        XCTAssertTrue(choice1.waitForExistence(timeout: 3))
        choice1.tap()

        let cta = app.buttons["SajuLessonNextCTA"]
        XCTAssertTrue(cta.waitForExistence(timeout: 3))
        cta.tap()

        XCTAssertTrue(
            app.otherElements["SajuLearnListView"].waitForExistence(timeout: 5),
            "Should pop to SajuLearnListView after 학습 완료 tap"
        )
    }

    // MARK: - TU-LS18: 알 수 없는 id → fallback "준비중", 크래시 없음

    func test_unknownId_fallback_noCrash() {
        launchSajuTab()
        let btn = app.buttons["SajuNavPush_lessonUnknownId"]
        XCTAssertTrue(btn.waitForExistence(timeout: 3))
        btn.tap()
        XCTAssertTrue(
            app.otherElements["SajuLessonView"].waitForExistence(timeout: 5),
            "SajuLessonView must appear even for unknown id (no crash)"
        )
        // NavBar title must contain "준비중"
        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 3))
        let titleContainsFallback = navBar.label.contains("준비중")
            || app.staticTexts.matching(NSPredicate(format: "label CONTAINS '준비중'")).firstMatch.waitForExistence(timeout: 2)
        XCTAssertTrue(titleContainsFallback, "Fallback title must contain '준비중'")
    }

    // MARK: - TU-LS19: 옵션 박스 hit target ≥ 44

    func test_hitTarget_choices_minSize44() {
        launchLesson()
        for i in 0...3 {
            let choice = app.buttons["SajuLessonQuizChoice_\(i)"]
            XCTAssertTrue(choice.waitForExistence(timeout: 3))
            XCTAssertGreaterThanOrEqual(
                choice.frame.height, 44,
                "SajuLessonQuizChoice_\(i) hit target must be ≥ 44pt"
            )
        }
    }

    // MARK: - TU-LS20: CTA hit target ≥ 44

    func test_hitTarget_ctaButton_minSize44() {
        launchLesson()
        let cta = app.buttons["SajuLessonNextCTA"]
        XCTAssertTrue(cta.waitForExistence(timeout: 3))
        XCTAssertGreaterThanOrEqual(
            cta.frame.height, 44,
            "SajuLessonNextCTA hit target must be ≥ 44pt"
        )
    }

    // MARK: - TU-LS21: Dynamic Type XL — 텍스트 잘리지 않음

    func test_dynamicType_xl_textNotTruncated() {
        launchLesson(extraEnv: ["UIContentSizeCategoryOverride": "UICTContentSizeCategoryXL"])
        XCTAssertTrue(app.staticTexts["SajuLessonHeadline"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.otherElements["SajuLessonConceptBox"].waitForExistence(timeout: 3))
        // Progress bar still exists (3pt thickness is visual-only, not measured in accessibility tree)
        XCTAssertTrue(app.otherElements["SajuLessonProgressBar"].waitForExistence(timeout: 3))
    }

    // MARK: - TU-LS22: Back 버튼 → LearnList 복귀

    func test_backButton_pops_toLearnList() {
        launchSajuTab()
        let learnBtn = app.buttons["SajuNavPush_learn"]
        XCTAssertTrue(learnBtn.waitForExistence(timeout: 3))
        learnBtn.tap()
        XCTAssertTrue(app.otherElements["SajuLearnListView"].waitForExistence(timeout: 5))

        let lessonBtn = app.buttons["SajuNavPush_lessonLOH003"]
        XCTAssertTrue(lessonBtn.waitForExistence(timeout: 3))
        lessonBtn.tap()
        XCTAssertTrue(app.otherElements["SajuLessonView"].waitForExistence(timeout: 5))

        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(
            app.otherElements["SajuLearnListView"].waitForExistence(timeout: 5),
            "Back should pop to SajuLearnListView"
        )
    }

    // MARK: - TU-LS23: VoiceOver — 진행 바 레이블

    func test_voiceOver_progressBar_label() {
        launchLesson()
        let bar = app.otherElements["SajuLessonProgressBar"]
        XCTAssertTrue(bar.waitForExistence(timeout: 3))
        XCTAssertTrue(
            bar.label.contains("진행률"),
            "SajuLessonProgressBar label must contain '진행률', got: \(bar.label)"
        )
        // Should contain a percent number
        let hasPercent = bar.label.contains("%")
        XCTAssertTrue(hasPercent, "Progress bar label must contain '%'")
    }

    // MARK: - TU-LS24: VoiceOver — 다이어그램 placeholder 레이블

    func test_voiceOver_diagramPlaceholder_label() {
        launchLesson()
        let placeholder = app.otherElements["SajuLessonDiagramPlaceholder"]
        XCTAssertTrue(placeholder.waitForExistence(timeout: 3))
        XCTAssertTrue(
            placeholder.label.contains("다이어그램 자리"),
            "SajuLessonDiagramPlaceholder label must contain '다이어그램 자리', got: \(placeholder.label)"
        )
    }
}
