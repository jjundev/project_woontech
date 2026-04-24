import SwiftUI

/// 접근성 체크박스(hit target ≥ 44pt). NFC-5.
struct SajuCheckbox: View {
    let titleKey: LocalizedStringKey
    @Binding var isChecked: Bool
    var isEnabled: Bool = true
    var identifier: String

    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            isChecked.toggle()
        }) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isChecked ? DesignTokens.ink : DesignTokens.gray2, lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(DesignTokens.ink)
                    }
                }
                Text(titleKey, bundle: .main)
                    .font(.system(size: 13))
                    .foregroundStyle(isEnabled ? DesignTokens.ink : DesignTokens.muted)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityIdentifier(identifier)
        .accessibilityAddTraits(isChecked ? [.isButton, .isSelected] : [.isButton])
    }
}
