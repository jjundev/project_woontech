import SwiftUI

/// 사주 탭 컨텐츠 슬롯 — 본 슬라이스(WF4-01)에서는 비어 있는 ScrollView +
/// "준비중" placeholder 텍스트만 렌더한다. 실제 컨텐츠는 WF4-02/03에서 채워진다.
struct SajuTabContentPlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                Text(String(
                    localized: "saju.tab.content.placeholder",
                    defaultValue: "준비중"
                ))
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(DesignTokens.muted)
                .accessibilityIdentifier("SajuTabContentPlaceholderText")
                Spacer().frame(height: 200)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("SajuTabContentPlaceholder")
    }
}
