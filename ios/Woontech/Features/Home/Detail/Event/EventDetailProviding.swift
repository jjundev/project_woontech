import Foundation

// MARK: - Data Model

struct EventDetailContent {
    let meaning: String
    let sajuRelationFormula: String
    let sajuRelationNote: String
    let investPerspectives: [String]
    let learnCTAText: String
}

// MARK: - Protocol

protocol EventDetailProviding {
    func content(for eventID: WeeklyEvent.ID) -> EventDetailContent
}

// MARK: - Mock Implementation

struct MockEventDetailProvider: EventDetailProviding {
    var meaning: String
    var sajuRelationFormula: String
    var sajuRelationNote: String
    var investPerspectives: [String]
    var learnCTAText: String

    init(
        meaning: String = "10년 주기로 바뀌는 큰 환경 변화. 기존 정재 중심에서 편관 중심으로 이동. 긴장감 있는 결정·변화의 시기.",
        sajuRelationFormula: String = "경금 일주 × 병진 대운 = 편관",
        sajuRelationNote: String = "압박과 성장이 공존하는 10년",
        investPerspectives: [String] = [
            "안정형 → 도전형 전환 신호",
            "단, 충동적 결정 경계",
            "새 자산군 탐색 참고 시기"
        ],
        learnCTAText: String = "📖 대운 학습하기 →"
    ) {
        self.meaning = meaning
        self.sajuRelationFormula = sajuRelationFormula
        self.sajuRelationNote = sajuRelationNote
        self.investPerspectives = investPerspectives
        self.learnCTAText = learnCTAText
    }

    func content(for eventID: WeeklyEvent.ID) -> EventDetailContent {
        EventDetailContent(
            meaning: meaning,
            sajuRelationFormula: sajuRelationFormula,
            sajuRelationNote: sajuRelationNote,
            investPerspectives: investPerspectives,
            learnCTAText: learnCTAText
        )
    }
}
