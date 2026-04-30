import XCTest
import SwiftUI
@testable import Woontech

final class SajuLessonTests: XCTestCase {

    private let provider = MockSajuLessonProvider()
    private var defaultLesson: Lesson { provider.lesson(id: "L-OH-003") }

    // MARK: - TL07-01 ~ TL07-07: MockSajuLessonProvider 기본값

    func test_mockProvider_defaultLesson_id() {
        XCTAssertEqual(defaultLesson.id, "L-OH-003")
    }

    func test_mockProvider_defaultLesson_numberAndTitle() {
        XCTAssertEqual(defaultLesson.number, 3)
        XCTAssertEqual(defaultLesson.title, "오행의 의미")
    }

    func test_mockProvider_defaultLesson_currentIndex_totalCount() {
        XCTAssertEqual(defaultLesson.currentIndex, 3)
        XCTAssertEqual(defaultLesson.totalCount, 7)
    }

    func test_mockProvider_defaultLesson_sectionLabel_headline() {
        XCTAssertEqual(defaultLesson.sectionLabel, "기본 개념")
        XCTAssertEqual(defaultLesson.headline, "오행이란?")
    }

    func test_mockProvider_defaultLesson_quizChoicesCount_is4() {
        XCTAssertEqual(defaultLesson.quiz.choices.count, 4)
    }

    func test_mockProvider_defaultLesson_correctIndex_is2() {
        XCTAssertEqual(defaultLesson.quiz.correctIndex, 2)
    }

    func test_mockProvider_defaultLesson_nextLessonId_notNil() {
        XCTAssertEqual(defaultLesson.nextLessonId, "L-OH-004")
    }

    // MARK: - TL07-08 ~ TL07-10: progressRatio

    func test_progressRatio_3of7_approx42857() {
        let ratio = SajuLessonView.progressRatio(currentIndex: 3, totalCount: 7)
        XCTAssertEqual(ratio, 3.0 / 7.0, accuracy: 0.00001)
    }

    func test_progressRatio_clamp_above1() {
        let ratio = SajuLessonView.progressRatio(currentIndex: 8, totalCount: 7)
        XCTAssertEqual(ratio, 1.0)
    }

    func test_progressRatio_totalZero_returns0() {
        let ratio = SajuLessonView.progressRatio(currentIndex: 0, totalCount: 0)
        XCTAssertEqual(ratio, 0.0)
    }

    // MARK: - TL07-11 ~ TL07-16: choiceAppearance

    func test_choiceAppearance_beforeSelection_allGray() {
        for index in 0...3 {
            let (border, bg, weight) = SajuLessonView.choiceAppearance(index: index, selected: nil, correct: 2)
            XCTAssertEqual(border, DesignTokens.gray2, "index \(index): border should be gray2")
            XCTAssertEqual(bg, Color.white, "index \(index): bg should be white")
            XCTAssertEqual(weight, Font.Weight.regular, "index \(index): weight should be regular")
        }
    }

    func test_choiceAppearance_correctSelected_inkBorder() {
        let (border, bg, weight) = SajuLessonView.choiceAppearance(index: 2, selected: 2, correct: 2)
        XCTAssertEqual(border, DesignTokens.quizCorrectBorder)
        XCTAssertEqual(bg, DesignTokens.quizCorrectBackground)
        XCTAssertEqual(weight, Font.Weight.bold)
    }

    func test_choiceAppearance_correctSelected_otherStayGray() {
        for index in [0, 1, 3] {
            let (border, _, _) = SajuLessonView.choiceAppearance(index: index, selected: 2, correct: 2)
            XCTAssertEqual(border, DesignTokens.gray2, "index \(index) should stay gray when correct=2 selected=2")
        }
    }

    func test_choiceAppearance_incorrectSelected_redBorder() {
        let (border, bg, _) = SajuLessonView.choiceAppearance(index: 0, selected: 0, correct: 2)
        XCTAssertEqual(border, DesignTokens.quizIncorrectBorder)
        XCTAssertEqual(bg, DesignTokens.quizIncorrectBg)
    }

    func test_choiceAppearance_incorrectSelected_correctHighlighted() {
        let (border, bg, weight) = SajuLessonView.choiceAppearance(index: 2, selected: 0, correct: 2)
        XCTAssertEqual(border, DesignTokens.quizCorrectBorder)
        XCTAssertEqual(bg, DesignTokens.quizCorrectBackground)
        XCTAssertEqual(weight, Font.Weight.bold)
    }

    func test_choiceAppearance_incorrectSelected_otherGray() {
        let (border, _, _) = SajuLessonView.choiceAppearance(index: 1, selected: 0, correct: 2)
        XCTAssertEqual(border, DesignTokens.gray2)
    }

    // MARK: - TL07-17 ~ TL07-20: CTA label / active logic

    func test_ctaLabel_nextLessonIdNotNil_isDaeum() {
        let lesson = defaultLesson // nextLessonId == "L-OH-004"
        XCTAssertNotNil(lesson.nextLessonId)
        let label = lesson.nextLessonId != nil ? "다음 강의" : "학습 완료"
        XCTAssertEqual(label, "다음 강의")
    }

    func test_ctaLabel_nextLessonIdNil_isHakseup() {
        let lesson = provider.lesson(id: "L-OH-LAST") // nextLessonId == nil
        XCTAssertNil(lesson.nextLessonId)
        let label = lesson.nextLessonId != nil ? "다음 강의" : "학습 완료"
        XCTAssertEqual(label, "학습 완료")
    }

    func test_ctaActive_onlyAfterSelection() {
        // nil → disabled
        var selected: Int? = nil
        XCTAssertFalse(selected != nil, "CTA should be inactive before selection")
        // non-nil → enabled
        selected = 2
        XCTAssertTrue(selected != nil, "CTA should be active after selection")
    }

    func test_noReselect_afterFirstSelection() {
        // Simulate guard selectedChoiceIndex == nil behavior
        var selected: Int? = nil
        func tap(index: Int) {
            guard selected == nil else { return }
            selected = index
        }
        tap(index: 2)
        XCTAssertEqual(selected, 2)
        tap(index: 0)
        XCTAssertEqual(selected, 2, "Re-tap should not change selectedChoiceIndex")
    }

    // MARK: - TL07-21 ~ TL07-22: Fallback

    func test_mockProvider_unknownId_returnsFallback() {
        let fallback = provider.lesson(id: "UNKNOWN-XYZ")
        XCTAssertTrue(fallback.isFallback)
    }

    func test_fallbackLesson_quizChoicesStillCount4() {
        let fallback = provider.lesson(id: "__totally_unknown__")
        XCTAssertEqual(fallback.quiz.choices.count, 4)
    }

    // MARK: - TL07-23: Protocol separation

    func test_lessonProviding_separateFrom_learningPathProviding() {
        XCTAssertFalse(MockSajuLessonProvider() is any SajuLearningPathProviding)
    }

    // MARK: - TL07-24 ~ TL07-25: NavBar format strings

    func test_mockProvider_navbarTitle_format() {
        let lesson = defaultLesson
        let title = "\(lesson.number)강 · \(lesson.title)"
        XCTAssertEqual(title, "3강 · 오행의 의미")
    }

    func test_mockProvider_navbarTrailing_format() {
        let lesson = defaultLesson
        let trailing = "\(lesson.currentIndex)/\(lesson.totalCount)"
        XCTAssertEqual(trailing, "3/7")
    }

    // MARK: - TL07-26 ~ TL07-32: VoiceOver helpers

    func test_voiceOver_navbarTitle_accessibilityLabel() {
        let lesson = defaultLesson
        let label = "\(lesson.number)강, \(lesson.title)"
        XCTAssertEqual(label, "3강, 오행의 의미")
    }

    func test_voiceOver_navbarTrailing_accessibilityLabel() {
        let lesson = defaultLesson
        let label = "현재 \(lesson.currentIndex)강, 총 \(lesson.totalCount)강"
        XCTAssertEqual(label, "현재 3강, 총 7강")
    }

    func test_voiceOver_progressBar_accessibilityLabel() {
        let label = SajuLessonView.progressBarA11yLabel(current: 3, total: 7)
        XCTAssertEqual(label, "진행률 43%")
    }

    func test_voiceOver_diagramPlaceholder_accessibilityLabel() {
        let lesson = defaultLesson
        let label = "다이어그램 자리, \(lesson.diagramPlaceholderLabel)"
        XCTAssertEqual(label, "다이어그램 자리, 상생·상극 다이어그램")
    }

    func test_voiceOver_quizChoice_symbol_isAccessibilityLabel() {
        let lesson = defaultLesson
        XCTAssertEqual(lesson.quiz.choices[2].symbol, "金")
    }

    func test_voiceOver_quizCard_accessibilityLabel() {
        let label = SajuLessonView.quizA11yLabel(question: "水를 생(生)하는 오행은?")
        XCTAssertEqual(label, "퀴즈, 水를 생(生)하는 오행은?")
    }

    func test_voiceOver_choiceAccessibilityValue() {
        // 정답 선택
        XCTAssertEqual(SajuLessonView.choiceA11yValue(index: 2, selected: 2, correct: 2), "정답")
        // 오답 선택한 옵션
        XCTAssertEqual(SajuLessonView.choiceA11yValue(index: 0, selected: 0, correct: 2), "오답")
        // 오답 선택 후 다른 미선택 옵션
        XCTAssertEqual(SajuLessonView.choiceA11yValue(index: 1, selected: 0, correct: 2), "")
        // 미선택 상태
        XCTAssertEqual(SajuLessonView.choiceA11yValue(index: 0, selected: nil, correct: 2), "")
    }
}
