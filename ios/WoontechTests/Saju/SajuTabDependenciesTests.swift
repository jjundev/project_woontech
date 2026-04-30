import XCTest
@testable import Woontech

private struct StubUserSajuOriginProvider: UserSajuOriginProviding {
    let pillars: [Pillar] = [
        Pillar(position: .hour,  heavenlyStem: "甲", earthlyBranch: "子", element: "wood"),
        Pillar(position: .day,   heavenlyStem: "乙", earthlyBranch: "丑", element: "wood"),
        Pillar(position: .month, heavenlyStem: "丙", earthlyBranch: "寅", element: "fire"),
        Pillar(position: .year,  heavenlyStem: "丁", earthlyBranch: "卯", element: "fire"),
    ]
    let dayMasterLine: String = "stub day master"
}

private struct StubSajuCategoriesProvider: SajuCategoriesProviding {
    let categories: [SajuCategorySummary] = [
        SajuCategorySummary(kind: .elements, title: "stub", summary: "stub", badge: nil)
    ]
}

private struct StubSajuElementsDetailProvider: SajuElementsDetailProviding {
    // WF4-04: summaryLine 제거, 4개 필드로 교체 (breaking change 대응)
    let summaryHeadline: String = "stub headline"
    let summaryBody: String = "stub body"
    let elements: [ElementDistribution] = MockSajuElementsDetailProvider.defaultElements
    let guidance: ElementGuidance? = nil
}

private struct StubSajuTenGodsDetailProvider: SajuTenGodsDetailProviding {
    let summaryHeadline: String = "stub tenGods"
    let summaryBody: String = "stub body"
    let groups: [TenGodGroup] = MockSajuTenGodsDetailProvider.defaultGroups
    let topThree: [CoreTenGod] = MockSajuTenGodsDetailProvider.defaultTopThree
    let absentWarning: AbsentWarning? = nil
    let learnEntry: LearnEntry? = nil
}

private struct StubSajuLearningPathProvider: SajuLearningPathProviding {
    let weeklyProgress = WeeklyProgress(completed: 1, goal: 2, streakDays: 0)
    let courses: [SajuCourse] = [
        SajuCourse(id: "stub", title: "Stub", lessonCount: 1, progress: 0.5, status: .current)
    ]
    // WF4-03 신규 프로퍼티 — default 구현이 없는 프로퍼티만 명시
    var featuredLesson: FeaturedLesson? { nil }
    var glossaryTermCount: Int { 0 }
}

private struct StubSajuLessonProvider: SajuLessonProviding {
    func lesson(id: String) -> Lesson {
        Lesson(
            id: id,
            number: 0,
            title: "stub-\(id)",
            currentIndex: 0,
            totalCount: 1,
            sectionLabel: "stub",
            headline: "stub",
            conceptBox: "stub",
            diagramPlaceholderLabel: "stub",
            quiz: Quiz(
                label: "stub",
                question: "stub",
                choices: [Choice(symbol: "A"), Choice(symbol: "B"), Choice(symbol: "C"), Choice(symbol: "D")],
                correctIndex: 0
            ),
            nextLessonId: nil,
            isFallback: false
        )
    }
}

final class SajuTabDependenciesTests: XCTestCase {

    // T4
    func test_sajuTabDependencies_mock_compilesAndDefaults() {
        let deps = SajuTabDependencies.mock

        XCTAssertFalse(deps.userSajuOrigin.dayMasterLine.isEmpty)
        XCTAssertEqual(deps.userSajuOrigin.pillars.count, 4)
        XCTAssertEqual(deps.categories.categories.count, 5)
        // WF4-04: summaryLine → summaryHeadline
        XCTAssertFalse(deps.elementsDetail.summaryHeadline.isEmpty)
        // WF4-05: summaryLine → summaryHeadline
        XCTAssertFalse(deps.tenGodsDetail.summaryHeadline.isEmpty)
        XCTAssertEqual(deps.learningPath.courses.count, 4)
        XCTAssertFalse(deps.lesson.lesson(id: "L-OH-003").isFallback)
    }

    // T5
    func test_sajuTabDependencies_customMockReplace_compiles() {
        let deps = SajuTabDependencies(
            userSajuOrigin: StubUserSajuOriginProvider(),
            categories: StubSajuCategoriesProvider(),
            elementsDetail: StubSajuElementsDetailProvider(),
            tenGodsDetail: StubSajuTenGodsDetailProvider(),
            learningPath: StubSajuLearningPathProvider(),
            lesson: StubSajuLessonProvider()
        )

        XCTAssertEqual(deps.userSajuOrigin.dayMasterLine, "stub day master")
        XCTAssertEqual(deps.userSajuOrigin.pillars.count, 4)
        XCTAssertEqual(deps.categories.categories.first?.title, "stub")
        // WF4-04: summaryLine → summaryHeadline
        XCTAssertEqual(deps.elementsDetail.summaryHeadline, "stub headline")
        // WF4-05: summaryLine → summaryHeadline
        XCTAssertEqual(deps.tenGodsDetail.summaryHeadline, "stub tenGods")
        XCTAssertEqual(deps.learningPath.courses.first?.id, "stub")
        XCTAssertEqual(deps.lesson.lesson(id: "stub-id").id, "stub-id")
    }
}
