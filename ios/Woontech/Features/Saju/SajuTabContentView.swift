import SwiftUI

/// `SajuTabView`의 NavigationStack 내부 root 뷰.
///
/// Block A(원국 카드)와 Block B(5개 카테고리 카드 섹션)를 ScrollView 안에 배치하며,
/// WF4-01의 `SajuTabContentPlaceholderView`를 교체한다.
/// WF4-03: below-fold 사주 공부하기 섹션(`SajuStudySectionView`)을 추가한다.
struct SajuTabContentView: View {
    let originProvider: any UserSajuOriginProviding
    let categoriesProvider: any SajuCategoriesProviding
    let learningPathProvider: any SajuLearningPathProviding
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

                // WF4-03 below-fold: 사주 공부하기 섹션 (18pt 상단 마진)
                SajuStudySectionView(
                    provider: learningPathProvider,
                    onNavigate: onNavigate
                )
                .padding(.top, 18)
            }
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("SajuTabContent")
    }
}
