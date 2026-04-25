import Foundation

protocol WeeklyEventsProviding {
    func events() -> [WeeklyEvent]
    func proFeatures() -> [String]
}

struct MockWeeklyEventsProvider: WeeklyEventsProviding {
    func events() -> [WeeklyEvent] {
        [
            WeeklyEvent(
                type: .daewoon,
                icon: "🔄",
                title: "대운 전환",
                hanja: "大運",
                dday: -89,
                ddayDate: "2026.05.12",
                impact: .positive,
                oneLiner: "새로운 10년 주기 — 병진 대운 진입",
                investContext: "안정형 → 도전형 전환 신호 · 새 자산군 탐색 참고 시기",
                badge: "중요",
                timeGroup: .within3Months
            ),
            WeeklyEvent(
                type: .jeolgi,
                icon: "🌿",
                title: "곡우(穀雨)",
                hanja: "穀雨",
                dday: -2,
                ddayDate: "4/25 토",
                impact: .neutral,
                oneLiner: "봄비의 절기 — 水 부족 해소 참고 시기",
                investContext: "월간 포지션 점검 참고 시기",
                badge: nil,
                timeGroup: .thisWeek
            ),
            WeeklyEvent(
                type: .hapchung,
                icon: "⚠",
                title: "월지충 · 卯↔酉",
                hanja: nil,
                dday: -4,
                ddayDate: "4/27 월",
                impact: .negative,
                oneLiner: "직업궁 충돌 — 부서 이동·갈등 주의",
                investContext: "충동적 결정 주의 · 관망 참고",
                badge: nil,
                timeGroup: .thisWeek
            ),
            WeeklyEvent(
                type: .special,
                icon: "⭐",
                title: "경신일 귀환",
                hanja: nil,
                dday: -18,
                ddayDate: "5/11 월",
                impact: .neutral,
                oneLiner: "내 일주와 같은 날 — 자기 성찰의 기회",
                investContext: "복기·성향 점검에 적합한 하루",
                badge: nil,
                timeGroup: .thisMonth
            ),
        ]
    }

    func proFeatures() -> [String] {
        [
            "6개월 흐름 리포트",
            "성향 vs 실제 행동 주간 리포트",
            "AI 사주 상담사",
        ]
    }

    init() {}
}
