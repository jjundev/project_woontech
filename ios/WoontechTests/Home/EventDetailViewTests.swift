import XCTest
@testable import Woontech

final class EventDetailViewTests: XCTestCase {

    // MARK: - U1: Default values — meaning, formula, note, learnCTAText

    func testDefaultMeaning_matchesWireframe() {
        let provider = MockEventDetailProvider()
        let content = provider.content(for: UUID())
        XCTAssertEqual(
            content.meaning,
            "10년 주기로 바뀌는 큰 환경 변화. 기존 정재 중심에서 편관 중심으로 이동. 긴장감 있는 결정·변화의 시기."
        )
    }

    func testDefaultSajuRelationFormula_matchesWireframe() {
        let provider = MockEventDetailProvider()
        let content = provider.content(for: UUID())
        XCTAssertEqual(content.sajuRelationFormula, "경금 일주 × 병진 대운 = 편관")
    }

    func testDefaultSajuRelationNote_matchesWireframe() {
        let provider = MockEventDetailProvider()
        let content = provider.content(for: UUID())
        XCTAssertEqual(content.sajuRelationNote, "압박과 성장이 공존하는 10년")
    }

    func testDefaultLearnCTAText_matchesWireframe() {
        let provider = MockEventDetailProvider()
        let content = provider.content(for: UUID())
        XCTAssertEqual(content.learnCTAText, "📖 대운 학습하기 →")
    }

    // MARK: - U2: Default investPerspectives — length 3 + content

    func testDefaultInvestPerspectives_lengthIsThree() {
        let provider = MockEventDetailProvider()
        let content = provider.content(for: UUID())
        XCTAssertEqual(content.investPerspectives.count, 3)
    }

    func testDefaultInvestPerspectives_firstItem() {
        let provider = MockEventDetailProvider()
        let content = provider.content(for: UUID())
        XCTAssertEqual(content.investPerspectives[0], "안정형 → 도전형 전환 신호")
    }

    func testDefaultInvestPerspectives_secondItem() {
        let provider = MockEventDetailProvider()
        let content = provider.content(for: UUID())
        XCTAssertEqual(content.investPerspectives[1], "단, 충동적 결정 경계")
    }

    func testDefaultInvestPerspectives_thirdItem() {
        let provider = MockEventDetailProvider()
        let content = provider.content(for: UUID())
        XCTAssertEqual(content.investPerspectives[2], "새 자산군 탐색 참고 시기")
    }

    // MARK: - U3: Custom meaning injection

    func testCustomMeaning_returnedFromContent() {
        let customMeaning = "커스텀 의미 텍스트"
        let provider = MockEventDetailProvider(meaning: customMeaning)
        let content = provider.content(for: UUID())
        XCTAssertEqual(content.meaning, customMeaning)
    }

    // MARK: - U4: Custom investPerspectives injection

    func testCustomInvestPerspectives_lengthAndContent() {
        let custom = ["항목1", "항목2", "항목3", "항목4"]
        let provider = MockEventDetailProvider(investPerspectives: custom)
        let content = provider.content(for: UUID())
        XCTAssertEqual(content.investPerspectives.count, 4)
        XCTAssertEqual(content.investPerspectives[0], "항목1")
        XCTAssertEqual(content.investPerspectives[3], "항목4")
    }

    // MARK: - U5: Custom sajuRelationFormula / sajuRelationNote injection

    func testCustomSajuRelationFormula_returnedFromContent() {
        let customFormula = "커스텀공식 × 테스트 = 결과"
        let provider = MockEventDetailProvider(sajuRelationFormula: customFormula)
        let content = provider.content(for: UUID())
        XCTAssertEqual(content.sajuRelationFormula, customFormula)
    }

    func testCustomSajuRelationNote_returnedFromContent() {
        let customNote = "커스텀 노트 텍스트"
        let provider = MockEventDetailProvider(sajuRelationNote: customNote)
        let content = provider.content(for: UUID())
        XCTAssertEqual(content.sajuRelationNote, customNote)
    }

    // MARK: - U6: Custom learnCTAText injection

    func testCustomLearnCTAText_returnedFromContent() {
        let customCTA = "커스텀CTA텍스트"
        let provider = MockEventDetailProvider(learnCTAText: customCTA)
        let content = provider.content(for: UUID())
        XCTAssertEqual(content.learnCTAText, customCTA)
    }

    // MARK: - U7: Empty investPerspectives → isEmpty == true

    func testEmptyInvestPerspectives_isEmptyTrue() {
        let provider = MockEventDetailProvider(investPerspectives: [])
        let content = provider.content(for: UUID())
        XCTAssertTrue(content.investPerspectives.isEmpty)
    }

    // MARK: - U8: Default learnCTAText is non-empty

    func testDefaultLearnCTAText_isNotEmpty() {
        let provider = MockEventDetailProvider()
        let content = provider.content(for: UUID())
        XCTAssertFalse(content.learnCTAText.isEmpty)
    }

    // MARK: - U9: WeeklyEvent.badge == nil

    func testWeeklyEvent_badgeNil_returnsNil() {
        let event = WeeklyEvent(
            type: .jeolgi,
            icon: "🌿",
            title: "곡우(穀雨)",
            dday: -2,
            ddayDate: "4/25 토",
            impact: .neutral,
            oneLiner: "봄비의 절기",
            investContext: "포지션 점검",
            badge: nil,
            timeGroup: .thisWeek
        )
        XCTAssertNil(event.badge)
    }

    // MARK: - U10: WeeklyEvent.badge != nil

    func testWeeklyEvent_badgeNonNil_returnsValue() {
        let event = WeeklyEvent(
            type: .daewoon,
            icon: "🔄",
            title: "대운 전환",
            dday: -89,
            ddayDate: "2026.05.12",
            impact: .positive,
            oneLiner: "새로운 10년 주기",
            investContext: "안정형 → 도전형",
            badge: "중요",
            timeGroup: .within3Months
        )
        XCTAssertNotNil(event.badge)
        XCTAssertEqual(event.badge, "중요")
    }

    // MARK: - U11: EventDetailView smoke test (no crash on creation)

    func testEventDetailView_creationDoesNotCrash() {
        let event = MockWeeklyEventsProvider().events()[0]
        let provider = MockEventDetailProvider()
        let view = EventDetailView(event: event, provider: provider)
        XCTAssertNotNil(view)
    }

    // MARK: - Additional: content(for:) ignores ID (returns same content for any ID)

    func testContentForAnyID_returnsSameContent() {
        let provider = MockEventDetailProvider()
        let id1 = UUID()
        let id2 = UUID()
        let c1 = provider.content(for: id1)
        let c2 = provider.content(for: id2)
        XCTAssertEqual(c1.meaning, c2.meaning)
        XCTAssertEqual(c1.learnCTAText, c2.learnCTAText)
    }

    // MARK: - Additional: full custom init injection

    func testFullCustomInit_allFieldsReturned() {
        let provider = MockEventDetailProvider(
            meaning: "의미A",
            sajuRelationFormula: "공식A",
            sajuRelationNote: "노트A",
            investPerspectives: ["항목A"],
            learnCTAText: "CTAA"
        )
        let content = provider.content(for: UUID())
        XCTAssertEqual(content.meaning, "의미A")
        XCTAssertEqual(content.sajuRelationFormula, "공식A")
        XCTAssertEqual(content.sajuRelationNote, "노트A")
        XCTAssertEqual(content.investPerspectives, ["항목A"])
        XCTAssertEqual(content.learnCTAText, "CTAA")
    }
}
