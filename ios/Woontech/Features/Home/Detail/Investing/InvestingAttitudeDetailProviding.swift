import Foundation

// MARK: - Data Models

struct ScoreBreakdownItem: Equatable {
    let name: String        // e.g., "위험 선호", "분석 의존"
    let value: Int          // 0~100; will be clamped in view
    let description: String // e.g., "신중한 투자 접근 선호"
}

// MARK: - Protocol

protocol InvestingAttitudeDetailProviding {
    var score: Int { get }                           // 0~100; clamped to range by view
    var attitudeName: String { get }                 // e.g., "신중한 탐험가"
    var oneLiner: String { get }                     // e.g., "공격보다 관찰이 내 성향에 맞아요"
    var breakdown: [ScoreBreakdownItem] { get }      // Array of breakdown items
    var recommendations: [String] { get }            // Array of recommendation strings
}

// MARK: - Mock Implementation

struct MockInvestingAttitudeDetailProvider: InvestingAttitudeDetailProviding {
    var score: Int
    var attitudeName: String
    var oneLiner: String
    var breakdown: [ScoreBreakdownItem]
    var recommendations: [String]

    init(
        score: Int = 72,
        attitudeName: String = "신중한 탐험가",
        oneLiner: String = "공격보다 관찰이 내 성향에 맞아요",
        breakdown: [ScoreBreakdownItem]? = nil,
        recommendations: [String]? = nil
    ) {
        self.score = score
        self.attitudeName = attitudeName
        self.oneLiner = oneLiner
        self.breakdown = breakdown ?? [
            ScoreBreakdownItem(
                name: "위험 선호",
                value: 45,
                description: "신중한 투자 접근을 선호합니다"
            ),
            ScoreBreakdownItem(
                name: "분석 의존",
                value: 78,
                description: "데이터와 정보에 기반한 의사결정"
            ),
            ScoreBreakdownItem(
                name: "감정 통제",
                value: 68,
                description: "감정적 판단보다 합리적 접근"
            )
        ]
        self.recommendations = recommendations ?? [
            "정기적인 포트폴리오 검토 및 리밸런싱",
            "다양한 자산군에 분산 투자하기",
            "장기적 관점에서 투자 계획 수립"
        ]
    }
}
