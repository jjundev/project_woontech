import SwiftUI

/// Block B — "내 사주 자세히" 섹션 헤더 + 5개 카테고리 카드 리스트.
///
/// 슬롯 순서는 항상 [오행 분포, 십성 분석, 대운·세운, 합충형파, 용신·희신]으로 고정.
/// provider에 해당 kind가 없으면 nil → "데이터 없음" placeholder 카드를 표시.
struct SajuCategoriesSection: View {
    let provider: any SajuCategoriesProviding
    let onNavigate: (SajuRoute) -> Void

    /// 항상 이 순서로 5슬롯 렌더.
    let displayOrder: [SajuCategorySummary.Kind] = [
        .elements, .tenGods, .daewoon, .hapchung, .yongsin
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("내 사주 자세히")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .accessibilityIdentifier("SajuDetailSectionHeader")

            VStack(spacing: 8) {
                ForEach(displayOrder, id: \.self) { kind in
                    let summary = provider.categories.first(where: { $0.kind == kind })
                    SajuCategoryCardView(
                        summary: summary,
                        kind: kind,
                        onTap: { onNavigate(route(for: kind)) }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }

    /// 카테고리 kind → SajuRoute 매핑.
    func route(for kind: SajuCategorySummary.Kind) -> SajuRoute {
        switch kind {
        case .elements: return .elements
        case .tenGods:  return .tenGods
        case .daewoon:  return .daewoonPlaceholder
        case .hapchung: return .hapchungPlaceholder
        case .yongsin:  return .yongsinPlaceholder
        }
    }
}
