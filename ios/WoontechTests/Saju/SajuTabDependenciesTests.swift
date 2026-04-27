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
    let summaryLine: String = "stub elements"
}

private struct StubSajuTenGodsDetailProvider: SajuTenGodsDetailProviding {
    let summaryLine: String = "stub tenGods"
}

private struct StubSajuLearningPathProvider: SajuLearningPathProviding {
    let weeklyProgress = WeeklyProgress(completed: 1, goal: 2, streakDays: 0)
    let courses: [SajuCourse] = [
        SajuCourse(id: "stub", title: "Stub", lessonCount: 1, progress: 0.5, status: .current)
    ]
}

private struct StubSajuLessonProvider: SajuLessonProviding {
    func lessonTitle(forId id: String) -> String? { "stub-\(id)" }
}

final class SajuTabDependenciesTests: XCTestCase {

    // T4
    func test_sajuTabDependencies_mock_compilesAndDefaults() {
        let deps = SajuTabDependencies.mock

        XCTAssertFalse(deps.userSajuOrigin.dayMasterLine.isEmpty)
        XCTAssertEqual(deps.userSajuOrigin.pillars.count, 4)
        XCTAssertEqual(deps.categories.categories.count, 5)
        XCTAssertFalse(deps.elementsDetail.summaryLine.isEmpty)
        XCTAssertFalse(deps.tenGodsDetail.summaryLine.isEmpty)
        XCTAssertEqual(deps.learningPath.courses.count, 4)
        XCTAssertNotNil(deps.lesson.lessonTitle(forId: "L-001"))
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
        XCTAssertEqual(deps.elementsDetail.summaryLine, "stub elements")
        XCTAssertEqual(deps.tenGodsDetail.summaryLine, "stub tenGods")
        XCTAssertEqual(deps.learningPath.courses.first?.id, "stub")
        XCTAssertEqual(deps.lesson.lessonTitle(forId: "L-001"), "stub-L-001")
    }
}
