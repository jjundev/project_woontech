import SwiftUI

/// 사주 탭 상단 고정 헤더.
///
/// 좌측 "사주" 타이틀 + 우측 원형 placeholder 아이콘. 후속 슬라이스에서
/// 우측 아이콘에 의미가 부여되면 교체된다.
struct SajuTabHeaderView: View {
    var onMenuTap: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            Text(String(localized: "saju.tab.title", defaultValue: "사주"))
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier("SajuTabHeaderTitle")
                .accessibilityLabel(Text(String(localized: "saju.tab.title", defaultValue: "사주")))

            Spacer(minLength: 8)

            Button(action: onMenuTap) {
                Circle()
                    .stroke(DesignTokens.line2, lineWidth: 1)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("SajuTabHeaderMenuButton")
            .accessibilityLabel(Text(String(
                localized: "saju.tab.menu.label",
                defaultValue: "사주 메뉴"
            )))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(DesignTokens.bg)
    }
}
