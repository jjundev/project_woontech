import XCTest
@testable import Woontech

final class SajuMockProvidersTests: XCTestCase {

    // T6
    func test_mockUserSajuOrigin_pillarsCountIs4() {
        let mock = MockUserSajuOriginProvider()
        XCTAssertEqual(mock.pillars.count, 4)
    }

    // T7
    func test_mockUserSajuOrigin_pillarsContain_時日月年() {
        let mock = MockUserSajuOriginProvider()
        let positions = Set(mock.pillars.map { $0.position })
        XCTAssertEqual(positions, Set(Pillar.Position.allCases),
                       "Mock pillars must contain exactly hour/day/month/year (時/日/月/年)")
        // Each position appears exactly once.
        for pos in Pillar.Position.allCases {
            XCTAssertEqual(mock.pillars.filter { $0.position == pos }.count, 1)
        }
    }

    // T8
    func test_mockUserSajuOrigin_dayMasterLine_isNotEmpty() {
        let mock = MockUserSajuOriginProvider()
        XCTAssertFalse(mock.dayMasterLine.isEmpty)
        // Wireframe expects 일간 / 丙火 substrings to remain in the default line.
        XCTAssertTrue(mock.dayMasterLine.contains("일간"))
        XCTAssertTrue(mock.dayMasterLine.contains("丙火"))
    }

    // T9
    func test_mockSajuCategories_count_is5() {
        let mock = MockSajuCategoriesProvider()
        XCTAssertEqual(mock.categories.count, 5)
        let kinds = Set(mock.categories.map { $0.kind })
        XCTAssertEqual(kinds, Set(SajuCategorySummary.Kind.allCases))
    }

    // T10
    func test_mockSajuLearningPath_courseCountIs4() {
        let mock = MockSajuLearningPathProvider()
        XCTAssertEqual(mock.courses.count, 4)
    }

    // T11
    func test_mockSajuLearningPath_progressIsInRange() {
        let mock = MockSajuLearningPathProvider()
        for course in mock.courses {
            XCTAssertGreaterThanOrEqual(course.progress, 0.0,
                                        "Course \(course.id) progress must be >= 0.0")
            XCTAssertLessThanOrEqual(course.progress, 1.0,
                                     "Course \(course.id) progress must be <= 1.0")
        }
    }

    // T12
    func test_mockSajuLearningPath_courseTitlesContain_입문오행십성대운() {
        let mock = MockSajuLearningPathProvider()
        let titles = Set(mock.courses.map { $0.title })
        XCTAssertEqual(titles, ["입문", "오행", "십성", "대운"])
    }
}
