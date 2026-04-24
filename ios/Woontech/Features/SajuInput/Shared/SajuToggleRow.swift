import SwiftUI

/// 토글 + 라벨 + 보조 문구 가로 배치. FR-6.3.
struct SajuToggleRow: View {
    let titleKey: LocalizedStringKey
    let subtitleKey: LocalizedStringKey?
    @Binding var isOn: Bool
    var identifier: String

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(titleKey, bundle: .main)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink)
                if let subtitleKey {
                    Text(subtitleKey, bundle: .main)
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.muted)
                }
            }
            Spacer(minLength: 12)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(DesignTokens.ink)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityIdentifier(identifier)
        }
    }
}
