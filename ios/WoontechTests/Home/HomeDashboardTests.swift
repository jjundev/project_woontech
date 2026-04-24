import XCTest
@testable import Woontech

final class HomeDashboardTests: XCTestCase {

    // MARK: - Badge label tests (AC-3, AC-4)

    func test_badgeLabel_zeroCount_returnsNil() {
        XCTAssertNil(badgeLabel(for: 0))
    }

    func test_badgeLabel_oneCount_returnsOne() {
        XCTAssertEqual(badgeLabel(for: 1), "1")
    }

    func test_badgeLabel_99_returns99() {
        XCTAssertEqual(badgeLabel(for: 99), "99")
    }

    func test_badgeLabel_100_returns99Plus() {
        XCTAssertEqual(badgeLabel(for: 100), "99+")
    }

    func test_badgeLabel_150_returns99Plus() {
        XCTAssertEqual(badgeLabel(for: 150), "99+")
    }

    // MARK: - Provider mock tests (AC-5)

    func test_mockUserProfile_defaultInitial() {
        let provider = MockUserProfileProvider()
        XCTAssertEqual(provider.avatarInitial, "홍")
    }

    // MARK: - HomeDependencies tests (AC-8)

    func test_homeDependencies_mock_compilesAndDefaultValues() {
        let deps = HomeDependencies.mock
        XCTAssertEqual(deps.userProfile.displayName, "홍길동")
        XCTAssertEqual(deps.notificationCenter.unreadCount, 2)
        // Verify all 5 fields are accessible (compile + non-nil check)
        _ = deps.heroInvesting
        _ = deps.insights
        _ = deps.weeklyEvents
    }

    func test_homeDependencies_customMockReplace_compiles() {
        struct CustomUserProfile: UserProfileProviding {
            var displayName: String { "민지" }
            var avatarInitial: String { "민" }
        }
        let deps = HomeDependencies(userProfile: CustomUserProfile())
        XCTAssertEqual(deps.userProfile.avatarInitial, "민")
    }

    // MARK: - HomeRoute Hashable tests (AC-9)

    func test_homeRoute_allCasesHashable() {
        let event = WeeklyEvent()
        let routes: Set<HomeRoute> = [
            .investing,
            .event(event),
            .today,
            .tabooPlaceholder,
            .practicePlaceholder
        ]
        XCTAssertEqual(routes.count, 5)
    }

    func test_homeRoute_event_hashEquality() {
        let sharedID = UUID()
        let event1 = WeeklyEvent(id: sharedID)
        let event2 = WeeklyEvent(id: sharedID)
        XCTAssertEqual(HomeRoute.event(event1), HomeRoute.event(event2))
    }
}
