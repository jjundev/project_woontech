import XCTest
@testable import Woontech

final class WeeklyEventsTests: XCTestCase {
    // MARK: - WeeklyEvent Model Tests

    func test_weeklyEvent_initialization_default() {
        // Given
        let id = UUID()

        // When
        let event = WeeklyEvent(
            id: id,
            type: .daewoon,
            icon: "🔄",
            title: "Test Event",
            dday: -10,
            ddayDate: "2026.05.01",
            impact: .positive,
            oneLiner: "Test description",
            investContext: "Test context",
            timeGroup: .thisWeek
        )

        // Then
        XCTAssertEqual(event.id, id)
        XCTAssertEqual(event.type, .daewoon)
        XCTAssertEqual(event.icon, "🔄")
        XCTAssertEqual(event.title, "Test Event")
        XCTAssertEqual(event.dday, -10)
        XCTAssertEqual(event.impact, .positive)
    }

    func test_weeklyEvent_hashable_sameID_equal() {
        // Given
        let id = UUID()
        let event1 = WeeklyEvent(
            id: id,
            type: .daewoon,
            icon: "🔄",
            title: "Event 1",
            dday: -10,
            ddayDate: "2026.05.01",
            impact: .positive,
            oneLiner: "Test",
            investContext: "Test",
            timeGroup: .thisWeek
        )
        let event2 = WeeklyEvent(
            id: id,
            type: .jeolgi,
            icon: "🌿",
            title: "Event 2",
            dday: -5,
            ddayDate: "2026.05.06",
            impact: .negative,
            oneLiner: "Different",
            investContext: "Different",
            timeGroup: .thisMonth
        )

        // When & Then
        XCTAssertEqual(event1, event2) // Same ID = equal
    }

    func test_weeklyEvent_identifiable_hasID() {
        // Given
        let id = UUID()
        let event = WeeklyEvent(
            id: id,
            type: .daewoon,
            icon: "🔄",
            title: "Test",
            dday: -10,
            ddayDate: "2026.05.01",
            impact: .positive,
            oneLiner: "Test",
            investContext: "Test",
            timeGroup: .thisWeek
        )

        // Then
        XCTAssertEqual(event.id, id)
    }

    // MARK: - EventType Enum Tests

    func test_eventType_allCases_decodable() {
        // Given
        let types: [EventType] = [.daewoon, .jeolgi, .hapchung, .special]

        // When & Then
        for type in types {
            let rawValue = type.rawValue
            XCTAssertFalse(rawValue.isEmpty)
            let decoded = EventType(rawValue: rawValue)
            XCTAssertEqual(decoded, type)
        }
    }

    // MARK: - Impact Enum Tests

    func test_impact_negativeCase_identified() {
        // Given
        let impact = Impact.negative

        // Then
        XCTAssertEqual(impact, .negative)
        XCTAssertNotEqual(impact, .positive)
        XCTAssertNotEqual(impact, .neutral)
    }

    // MARK: - TimeGroup Enum Tests

    func test_timeGroup_thisWeek_stringValue() {
        // Given
        let timeGroup = TimeGroup.thisWeek

        // Then
        XCTAssertEqual(timeGroup.displayName, "이번 주")
        XCTAssertEqual(timeGroup.rawValue, "이번 주")
    }

    func test_timeGroup_thisMonth_stringValue() {
        // Given
        let timeGroup = TimeGroup.thisMonth

        // Then
        XCTAssertEqual(timeGroup.displayName, "이번 달")
    }

    func test_timeGroup_within3Months_stringValue() {
        // Given
        let timeGroup = TimeGroup.within3Months

        // Then
        XCTAssertEqual(timeGroup.displayName, "3개월 이내")
    }

    // MARK: - MockWeeklyEventsProvider Tests

    func test_mockWeeklyEventsProvider_returns4Events() {
        // Given
        let provider = MockWeeklyEventsProvider()

        // When
        let events = provider.events()

        // Then
        XCTAssertEqual(events.count, 4)
    }

    func test_mockWeeklyEventsProvider_event0_isDaewoon() {
        // Given
        let provider = MockWeeklyEventsProvider()

        // When
        let events = provider.events()
        let event0 = events[0]

        // Then
        XCTAssertEqual(event0.type, .daewoon)
        XCTAssertEqual(event0.title, "대운 전환")
    }

    func test_mockWeeklyEventsProvider_event1_isThisWeek() {
        // Given
        let provider = MockWeeklyEventsProvider()

        // When
        let events = provider.events()
        let event1 = events[1]

        // Then
        XCTAssertEqual(event1.timeGroup, .thisWeek)
    }

    func test_mockWeeklyEventsProvider_event2_isNegativeImpact() {
        // Given
        let provider = MockWeeklyEventsProvider()

        // When
        let events = provider.events()
        let event2 = events[2]

        // Then
        XCTAssertEqual(event2.impact, .negative)
    }

    func test_mockWeeklyEventsProvider_event3_isThisMonth() {
        // Given
        let provider = MockWeeklyEventsProvider()

        // When
        let events = provider.events()
        let event3 = events[3]

        // Then
        XCTAssertEqual(event3.timeGroup, .thisMonth)
    }

    func test_mockWeeklyEventsProvider_proFeatures_returns3() {
        // Given
        let provider = MockWeeklyEventsProvider()

        // When
        let features = provider.proFeatures()

        // Then
        XCTAssertEqual(features.count, 3)
    }

    func test_mockWeeklyEventsProvider_proFeatures_correctText() {
        // Given
        let provider = MockWeeklyEventsProvider()

        // When
        let features = provider.proFeatures()

        // Then
        XCTAssertEqual(features[0], "6개월 흐름 리포트")
        XCTAssertEqual(features[1], "성향 vs 실제 행동 주간 리포트")
        XCTAssertEqual(features[2], "AI 사주 상담사")
    }

    // MARK: - Event Filtering Tests

    func test_eventFilter_byTimeGroup_thisWeek() {
        // Given
        let provider = MockWeeklyEventsProvider()
        let events = provider.events()

        // When
        let thisWeekEvents = events.filter { $0.timeGroup == .thisWeek }

        // Then
        XCTAssertEqual(thisWeekEvents.count, 2)
    }

    func test_eventFilter_byTimeGroup_thisMonth() {
        // Given
        let provider = MockWeeklyEventsProvider()
        let events = provider.events()

        // When
        let thisMonthEvents = events.filter { $0.timeGroup == .thisMonth }

        // Then
        XCTAssertEqual(thisMonthEvents.count, 1)
    }

    func test_eventFilter_byTimeGroup_within3Months() {
        // Given
        let provider = MockWeeklyEventsProvider()
        let events = provider.events()

        // When
        let within3MonthsEvents = events.filter { $0.timeGroup == .within3Months }

        // Then
        XCTAssertEqual(within3MonthsEvents.count, 1)
    }

    func test_eventFilter_empty_returnsNone() {
        // Given
        let events: [WeeklyEvent] = []

        // When
        let filtered = events.filter { $0.timeGroup == .thisWeek }

        // Then
        XCTAssertEqual(filtered.count, 0)
    }

    // MARK: - Impact Styling Logic Tests

    func test_negativeImpact_borderColor_isRed() {
        // Given
        let negativeEvent = WeeklyEvent(
            type: .hapchung,
            icon: "⚠",
            title: "Negative Event",
            dday: -4,
            ddayDate: "4/27 월",
            impact: .negative,
            oneLiner: "Test",
            investContext: "Test",
            timeGroup: .thisWeek
        )

        // Then
        XCTAssertEqual(negativeEvent.impact, .negative)
    }

    func test_positiveImpactWithBadge_badgeShown() {
        // Given
        let event = WeeklyEvent(
            type: .daewoon,
            icon: "🔄",
            title: "Positive Event",
            dday: -89,
            ddayDate: "2026.05.12",
            impact: .positive,
            oneLiner: "Test",
            investContext: "Test",
            badge: "중요",
            timeGroup: .within3Months
        )

        // Then
        XCTAssertEqual(event.impact, .positive)
        XCTAssertEqual(event.badge, "중요")
    }

    func test_positiveImpactWithoutBadge_badgeHidden() {
        // Given
        let event = WeeklyEvent(
            type: .daewoon,
            icon: "🔄",
            title: "Positive Event",
            dday: -89,
            ddayDate: "2026.05.12",
            impact: .positive,
            oneLiner: "Test",
            investContext: "Test",
            badge: nil,
            timeGroup: .within3Months
        )

        // Then
        XCTAssertEqual(event.impact, .positive)
        XCTAssertNil(event.badge)
    }

    func test_neutralImpact_noRedStyling() {
        // Given
        let event = WeeklyEvent(
            type: .jeolgi,
            icon: "🌿",
            title: "Neutral Event",
            dday: -2,
            ddayDate: "4/25 토",
            impact: .neutral,
            oneLiner: "Test",
            investContext: "Test",
            timeGroup: .thisWeek
        )

        // Then
        XCTAssertEqual(event.impact, .neutral)
        XCTAssertNotEqual(event.impact, .negative)
    }
}
