import SwiftUI

/// `SajuRoute` 목적지 placeholder.
///
/// 본 슬라이스(WF4-01)에서는 7케이스 모두 동일한 "준비중" 화면을 표시한다.
/// `lesson(id:)`는 화면에 식별자를 함께 표시해 associated value 전달을 검증한다.
/// WF4-04~07에서 각 라우트별 실제 화면으로 교체된다.
struct SajuPlaceholderDestinationView: View {
    let routeKey: String
    /// `lesson` 라우트의 경우에만 채워지는 식별자(예: "L-001").
    var identifier: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            Text(String(
                localized: "saju.tab.content.placeholder",
                defaultValue: "준비중"
            ))
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(DesignTokens.muted)
            .accessibilityIdentifier("SajuPlaceholderDestination_\(routeKey)_Text")

            if let identifier {
                Text(identifier)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink)
                    .accessibilityIdentifier("SajuPlaceholderDestination_\(routeKey)_Identifier")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(DesignTokens.bg)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("SajuPlaceholderDestination_\(routeKey)")
    }
}

/// 한 곳에서 라우트 → 목적지 View로 매핑한다.
@ViewBuilder
func sajuRouteDestination(for route: SajuRoute) -> some View {
    switch route {
    case .elements:
        SajuPlaceholderDestinationView(routeKey: "elements")
    case .tenGods:
        SajuPlaceholderDestinationView(routeKey: "tenGods")
    case .learn:
        SajuPlaceholderDestinationView(routeKey: "learn")
    case .lesson(let id):
        SajuPlaceholderDestinationView(routeKey: "lesson", identifier: id)
    case .daewoonPlaceholder:
        SajuPlaceholderDestinationView(routeKey: "daewoon")
    case .hapchungPlaceholder:
        SajuPlaceholderDestinationView(routeKey: "hapchung")
    case .yongsinPlaceholder:
        SajuPlaceholderDestinationView(routeKey: "yongsin")
    }
}
