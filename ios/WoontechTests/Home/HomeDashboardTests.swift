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
        let event = WeeklyEvent(
            type: .daewoon,
            icon: "🔄",
            title: "Test Event",
            dday: -10,
            ddayDate: "2026.05.01",
            impact: .positive,
            oneLiner: "Test",
            investContext: "Test",
            timeGroup: .thisWeek
        )
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
        let event1 = WeeklyEvent(
            id: sharedID,
            type: .daewoon,
            icon: "🔄",
            title: "Test Event",
            dday: -10,
            ddayDate: "2026.05.01",
            impact: .positive,
            oneLiner: "Test",
            investContext: "Test",
            timeGroup: .thisWeek
        )
        let event2 = WeeklyEvent(
            id: sharedID,
            type: .daewoon,
            icon: "🔄",
            title: "Test Event",
            dday: -10,
            ddayDate: "2026.05.01",
            impact: .positive,
            oneLiner: "Test",
            investContext: "Test",
            timeGroup: .thisWeek
        )
        XCTAssertEqual(HomeRoute.event(event1), HomeRoute.event(event2))
    }

    // MARK: - WF3-02 Hero date formatting (AC-2)

    func test_heroDate_jan1_2026_isThursday() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd EEEE"
        formatter.locale = Locale(identifier: "ko_KR")

        var comps = DateComponents()
        comps.year = 2026; comps.month = 1; comps.day = 1
        let date = Calendar.current.date(from: comps)!

        XCTAssertEqual(formatter.string(from: date), "2026.01.01 목요일")
    }

    func test_heroDate_apr23_2026_isThursday() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd EEEE"
        formatter.locale = Locale(identifier: "ko_KR")

        var comps = DateComponents()
        comps.year = 2026; comps.month = 4; comps.day = 23
        let date = Calendar.current.date(from: comps)!

        XCTAssertEqual(formatter.string(from: date), "2026.04.23 목요일")
    }

    // MARK: - WF3-02 Hero score clamping (AC-4)

    func test_heroScore_clamp_120_to_100() {
        XCTAssertEqual(clampHeroScore(120), 100)
    }

    func test_heroScore_clamp_negative_to_0() {
        XCTAssertEqual(clampHeroScore(-5), 0)
    }

    func test_heroScore_inRange_unchanged() {
        XCTAssertEqual(clampHeroScore(72), 72)
    }

    // MARK: - WF3-02 MockHeroInvestingProvider defaults (AC-5)

    func test_mockHeroInvesting_defaults() {
        let provider = MockHeroInvestingProvider()
        XCTAssertEqual(provider.score, 72)
        XCTAssertEqual(provider.oneLiner, "공격보다 관찰이 내 성향에 맞아요")
    }

    // MARK: - WF3-02 Insights card count and order (AC-7/8)

    func test_insightsCard_count_3() {
        XCTAssertEqual(MockInsightsProvider().cards.count, 3)
    }

    func test_insightsCard_slot0_isTaboo() {
        XCTAssertEqual(MockInsightsProvider().cards[0].badgeLabel, "금기")
    }

    func test_insightsCard_slot1_isToday() {
        XCTAssertEqual(MockInsightsProvider().cards[1].badgeLabel, "일진")
    }

    func test_insightsCard_slot2_isPractice() {
        XCTAssertEqual(MockInsightsProvider().cards[2].badgeLabel, "실천")
    }

    // MARK: - WF3-02 Safe subscript (AC-14)

    func test_insights_safeSubscript_outOfBounds() {
        let empty: [InsightCard] = []
        XCTAssertNil(empty[safe: 0])
    }

    func test_insights_2cardProvider_slot2_isNil() {
        let twoCards = Array(MockInsightsProvider().cards.prefix(2))
        XCTAssertNil(twoCards[safe: 2])
    }
}
