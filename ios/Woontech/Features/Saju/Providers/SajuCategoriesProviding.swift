import Foundation

/// 사주 탭 홈의 5개 카테고리 카드 요약.
///
/// WF4-02에서 본격 사용. WF4-01에서는 시그니처 + 와이어프레임 기본값만
/// 노출하고 SajuTabView에서 직접 그리지 않는다.
struct SajuCategorySummary: Hashable {
    enum Kind: String, Hashable, CaseIterable {
        case elements
        case tenGods
        case daewoon
        case hapchung
        case yongsin
    }

    let kind: Kind
    let title: String
    let summary: String
    let badge: String?
}

protocol SajuCategoriesProviding {
    /// 5개 카테고리(elements/tenGods/daewoon/hapchung/yongsin) 요약.
    var categories: [SajuCategorySummary] { get }
}

struct MockSajuCategoriesProvider: SajuCategoriesProviding {
    var categories: [SajuCategorySummary]

    init(categories: [SajuCategorySummary] = MockSajuCategoriesProvider.defaultCategories) {
        self.categories = categories
    }

    /// 와이어프레임(screens-06-saju-tab.jsx) 기본 텍스트.
    static let defaultCategories: [SajuCategorySummary] = [
        SajuCategorySummary(
            kind: .elements,
            title: "오행 분포",
            summary: "火 3 · 金 2 · 木 1 · 水 0 · 土 2",
            badge: "부족: 水"
        ),
        SajuCategorySummary(
            kind: .tenGods,
            title: "십성 분석",
            summary: "비견·식신·정재 강함",
            badge: nil
        ),
        SajuCategorySummary(
            kind: .daewoon,
            title: "대운 · 세운",
            summary: "현재 丁巳 대운 (32~41)",
            badge: "전환기"
        ),
        SajuCategorySummary(
            kind: .hapchung,
            title: "합충형파",
            summary: "일지-시지 合, 월지 沖",
            badge: nil
        ),
        SajuCategorySummary(
            kind: .yongsin,
            title: "용신 · 희신",
            summary: "水 용신, 金 희신",
            badge: nil
        ),
    ]
}
