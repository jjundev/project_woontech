import SwiftUI

struct InsightCard {
    let badgeLabel: String      // 예: "금기"
    let badgeColor: Color       // DesignTokens 토큰 참조
    let icon: String            // SF Symbol name
    let title: String           // bold 제목
    let desc: String            // 멀티라인; \n 포함 가능
    let bottomLabel: String     // 하단 캡션, 예: "오늘의 금기"
}

protocol InsightsProviding {
    var cards: [InsightCard] { get }   // 뷰는 인덱스 0=금기, 1=일진, 2=실천 고정 매핑
}

struct MockInsightsProvider: InsightsProviding {
    var cards: [InsightCard] {
        [
            InsightCard(
                badgeLabel: "금기",
                badgeColor: DesignTokens.tabooColor,
                icon: "exclamationmark.triangle",
                title: "큰 거래 자제",
                desc: "오늘은 큰 거래보다\n작은 수익에 집중하세요",
                bottomLabel: "오늘의 금기"
            ),
            InsightCard(
                badgeLabel: "일진",
                badgeColor: DesignTokens.todayColor,
                icon: "sun.max",
                title: "목(木)의 기운",
                desc: "목의 기운이 강한 날로\n새로운 시작에 좋아요",
                bottomLabel: "오늘의 일진"
            ),
            InsightCard(
                badgeLabel: "실천",
                badgeColor: DesignTokens.practiceColor,
                icon: "checkmark.circle",
                title: "리밸런싱 점검",
                desc: "포트폴리오를 점검하고\n목표 비중을 재조정하세요",
                bottomLabel: "오늘의 실천"
            ),
        ]
    }

    init() {}
}
