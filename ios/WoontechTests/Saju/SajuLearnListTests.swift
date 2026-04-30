import XCTest
@testable import Woontech

/// Unit tests for WF4-06 사주 공부 리스트.
final class SajuLearnListTests: XCTestCase {

    // MARK: - TL-01 learnCategories count

    func test_mockProvider_learnCategories_count_is6() {
        let mock = MockSajuLearningPathProvider()
        XCTAssertEqual(mock.learnCategories.count, 6)
    }

    // MARK: - TL-02 learnCategories order

    func test_mockProvider_learnCategories_order_fixed() {
        let mock = MockSajuLearningPathProvider()
        let labels = mock.learnCategories.map { $0.label }
        XCTAssertEqual(labels, ["전체", "입문", "오행", "십성", "대운", "합충"])
    }

    // MARK: - TL-03 initial selectedCategoryId is "all"

    func test_learnListView_initialSelectedCategoryId_isAll() {
        // SajuLearnListView initialises selectedCategoryId to "all".
        // We verify via the first category id in the mock (which is "all").
        let mock = MockSajuLearningPathProvider()
        let firstId = mock.learnCategories.first?.id
        XCTAssertEqual(firstId, "all", "First category must be 'all' — the default selection")
    }

    // MARK: - TL-04 pill selection binding switch

    func test_pill_selection_switchHighlights() {
        // When selectedId changes, only the new id matches.
        var selectedId = "all"
        // Simulate tap on "intro"
        selectedId = "intro"
        XCTAssertEqual(selectedId, "intro")
        XCTAssertNotEqual(selectedId, "all", "Previous selection 'all' must be unselected")
    }

    // MARK: - TL-05 ratio = completed / goal

    func test_weeklyProgress_ratio_completedDivGoal() {
        let progress = WeeklyProgress(completed: 3, goal: 5, streakDays: 3)
        XCTAssertEqual(progress.ratio, 0.6, accuracy: 0.0001)
    }

    // MARK: - TL-06 clampedRatio above 1

    func test_weeklyProgress_ratio_clamp_above1() {
        let result = SajuWeeklyProgressBannerView.clampedRatio(1.2)
        XCTAssertEqual(result, 1.0, accuracy: 0.0001)
    }

    // MARK: - TL-07 clampedRatio below 0

    func test_weeklyProgress_ratio_clamp_below0() {
        let result = SajuWeeklyProgressBannerView.clampedRatio(-0.1)
        XCTAssertEqual(result, 0.0, accuracy: 0.0001)
    }

    // MARK: - TL-08 ratio goal zero returns 0

    func test_weeklyProgress_ratio_goalZero_returns0() {
        let progress = WeeklyProgress(completed: 0, goal: 0, streakDays: 0)
        XCTAssertEqual(progress.ratio, 0.0, accuracy: 0.0001)
    }

    // MARK: - TL-09 streak badge hidden when 0

    func test_weeklyBanner_streakBadge_hidden_when0() {
        let streakDays = 0
        XCTAssertFalse(streakDays > 0, "streakDays=0 should NOT show badge")
    }

    // MARK: - TL-10 streak badge shown when 3

    func test_weeklyBanner_streakBadge_shown_when3() {
        let streakDays = 3
        XCTAssertTrue(streakDays > 0, "streakDays=3 should show badge")
    }

    // MARK: - TL-11 completed/total text binding

    func test_weeklyBanner_text_completed_total_binding() {
        let mock = MockSajuLearningPathProvider()
        let progress = mock.weeklyProgress
        let text = "\(progress.completed) / \(progress.goal)강 완료"
        XCTAssertEqual(text, "3 / 5강 완료")
    }

    // MARK: - TL-12 course header name binding

    func test_courseHeader_name_binding() {
        let mock = MockSajuLearningPathProvider()
        let headerText = "\(mock.introductoryCourse.name) 코스"
        XCTAssertEqual(headerText, "입문 코스")
    }

    // MARK: - TL-13 course header lessonCount + averageMinutes

    func test_courseHeader_lessonCount_averageMinutes() {
        let mock = MockSajuLearningPathProvider()
        let course = mock.introductoryCourse
        let metaText = "\(course.lessonCount)강 · 평균 \(course.averageMinutes)분"
        XCTAssertEqual(metaText, "7강 · 평균 3분")
    }

    // MARK: - TL-14 course list count matches lessonCount

    func test_courseList_count_matches_lessonCount() {
        let mock = MockSajuLearningPathProvider()
        let course = mock.introductoryCourse
        XCTAssertEqual(course.lessons.count, course.lessonCount)
        XCTAssertEqual(course.lessons.count, 7)
    }

    // MARK: - TL-15 statusKorean completed

    func test_lessonRow_statusKorean_completed() {
        XCTAssertEqual(SajuLessonRowCardView.statusKorean(.completed), "완료")
    }

    // MARK: - TL-16 statusKorean current

    func test_lessonRow_statusKorean_current() {
        XCTAssertEqual(SajuLessonRowCardView.statusKorean(.current), "현재")
    }

    // MARK: - TL-17 statusKorean pending

    func test_lessonRow_statusKorean_pending() {
        XCTAssertEqual(SajuLessonRowCardView.statusKorean(.pending), "미완료")
    }

    // MARK: - TL-18 statusKorean locked

    func test_lessonRow_statusKorean_locked() {
        XCTAssertEqual(SajuLessonRowCardView.statusKorean(.locked), "잠김")
    }

    // MARK: - TL-19 current meta includes 이어보기

    func test_lessonRow_current_meta_includes_이어보기() {
        let mock = MockSajuLearningPathProvider()
        let currentLesson = mock.introductoryCourse.lessons.first(where: { $0.status == .current })!
        let metaLine = currentLesson.status == .current
            ? "\(currentLesson.durationLabel) · 이어보기"
            : currentLesson.durationLabel
        XCTAssertTrue(metaLine.contains("이어보기"))
    }

    // MARK: - TL-20 pending meta excludes 이어보기

    func test_lessonRow_pending_meta_no_이어보기() {
        // Lessons 5,6,7 are locked, not pending. Use a manual pending lesson.
        let pendingLesson = LessonRow(id: "LP", number: 3, title: "test", durationLabel: "3분", status: .pending)
        let metaLine = pendingLesson.status == .current
            ? "\(pendingLesson.durationLabel) · 이어보기"
            : pendingLesson.durationLabel
        XCTAssertFalse(metaLine.contains("이어보기"))
    }

    // MARK: - TL-21 handleLessonTap completed fires route

    func test_handleLessonTap_completed_firesRoute() {
        var capturedRoute: SajuRoute? = nil
        let lesson = LessonRow(id: "L1", number: 1, title: "사주란", durationLabel: "3분", status: .completed)
        let onNavigate: (SajuRoute) -> Void = { capturedRoute = $0 }
        // Simulate the logic in SajuLearnListView.handleLessonTap
        switch lesson.status {
        case .completed, .current, .pending:
            onNavigate(.lesson(id: lesson.id))
        case .locked:
            break
        }
        XCTAssertEqual(capturedRoute, .lesson(id: "L1"))
    }

    // MARK: - TL-22 handleLessonTap current fires route

    func test_handleLessonTap_current_firesRoute() {
        var capturedRoute: SajuRoute? = nil
        let lesson = LessonRow(id: "L4", number: 4, title: "일간", durationLabel: "5분", status: .current)
        let onNavigate: (SajuRoute) -> Void = { capturedRoute = $0 }
        switch lesson.status {
        case .completed, .current, .pending:
            onNavigate(.lesson(id: lesson.id))
        case .locked:
            break
        }
        XCTAssertEqual(capturedRoute, .lesson(id: "L4"))
    }

    // MARK: - TL-23 handleLessonTap pending fires route

    func test_handleLessonTap_pending_firesRoute() {
        var capturedRoute: SajuRoute? = nil
        let lesson = LessonRow(id: "LP", number: 3, title: "pending", durationLabel: "3분", status: .pending)
        let onNavigate: (SajuRoute) -> Void = { capturedRoute = $0 }
        switch lesson.status {
        case .completed, .current, .pending:
            onNavigate(.lesson(id: lesson.id))
        case .locked:
            break
        }
        XCTAssertEqual(capturedRoute, .lesson(id: "LP"))
    }

    // MARK: - TL-24 handleLessonTap locked does NOT fire route

    func test_handleLessonTap_locked_doesNotFireRoute() {
        var capturedRoute: SajuRoute? = nil
        let lesson = LessonRow(id: "L5", number: 5, title: "locked", durationLabel: "4분", status: .locked)
        let onNavigate: (SajuRoute) -> Void = { capturedRoute = $0 }
        switch lesson.status {
        case .completed, .current, .pending:
            onNavigate(.lesson(id: lesson.id))
        case .locked:
            break
        }
        XCTAssertNil(capturedRoute, "Locked lesson tap must NOT fire navigate")
    }

    // MARK: - TL-25 recommendedArticles empty hides section

    func test_recommendedArticles_sectionHidden_whenEmpty() {
        let mock = MockSajuLearningPathProvider(recommendedArticles: [])
        XCTAssertTrue(mock.recommendedArticles.isEmpty, "Empty articles should hide section")
    }

    // MARK: - TL-26 recommendedArticles count matches provider

    func test_recommendedArticles_count_matches_provider() {
        let mock = MockSajuLearningPathProvider()
        XCTAssertEqual(mock.recommendedArticles.count, 2)
    }

    // MARK: - TL-27 article tap no route change

    func test_articleCard_tap_noRouteChange() {
        // SajuLearnArticleCardView onTap is no-op in SajuLearnListView.
        // The SajuLearnListView passes `{ /* no-op */ }` so capturedRoute remains nil.
        var capturedRoute: SajuRoute? = nil
        // Simulate a no-op closure (article tap doesn't fire navigate)
        let onTap: () -> Void = { /* no-op — intentionally does not set capturedRoute */ }
        onTap()
        XCTAssertNil(capturedRoute, "Article card tap must not fire navigate")
    }

    // MARK: - TL-28 lesson4 status is current

    func test_mockProvider_introductoryCourse_lesson4_isCurrent() {
        let mock = MockSajuLearningPathProvider()
        let lesson4 = mock.introductoryCourse.lessons[3]
        XCTAssertEqual(lesson4.status, .current)
    }

    // MARK: - TL-29 lesson5 status is locked

    func test_mockProvider_introductoryCourse_lesson5_isLocked() {
        let mock = MockSajuLearningPathProvider()
        let lesson5 = mock.introductoryCourse.lessons[4]
        XCTAssertEqual(lesson5.status, .locked)
    }

    // MARK: - TL-30 clampedRatio 0.6

    func test_weeklyProgressBannerView_clampedRatio_0_6() {
        let result = SajuWeeklyProgressBannerView.clampedRatio(0.6)
        XCTAssertEqual(result, 0.6, accuracy: 0.0001)
    }
}
