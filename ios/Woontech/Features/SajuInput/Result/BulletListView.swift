import SwiftUI

/// 불릿 리스트(강점/주의점/접근 공용). FR-8.2.4~6.
struct BulletListView: View {
    enum Style {
        case strength
        case caution
        case approach
    }

    let style: Style
    let titleKey: LocalizedStringKey
    let items: [String]
    let identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titleKey, bundle: .main)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, text in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(bulletColor)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        Text(text)
                            .font(.system(size: 13))
                            .foregroundStyle(DesignTokens.ink)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
        .accessibilityIdentifier(identifier)
    }

    private var bulletColor: Color {
        switch style {
        case .strength: return DesignTokens.ink
        case .caution:  return Color(red: 0.80, green: 0.15, blue: 0.15)
        case .approach: return DesignTokens.muted
        }
    }
}
