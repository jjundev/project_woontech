import SwiftUI

/// `SajuTabView`의 NavigationStack 내부 root 뷰.
///
/// Block A(원국 카드)와 Block B(5개 카테고리 카드 섹션)를 ScrollView 안에 배치하며,
/// WF4-01의 `SajuTabContentPlaceholderView`를 교체한다.
struct SajuTabContentView: View {
    let originProvider: any UserSajuOriginProviding
    let categoriesProvider: any SajuCategoriesProviding
    let onNavigate: (SajuRoute) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SajuOriginCardView(
                    provider: originProvider,
                    onViewAll: { /* no-op — 전체 보기 화면은 WF4 범위 외 */ }
                )

                SajuCategoriesSection(
                    provider: categoriesProvider,
                    onNavigate: onNavigate
                )

                // WF4-03 섹션 공간 예약
                Spacer(minLength: 32)
            }
            .padding(.top, 16)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("SajuTabContent")
    }
}
