import SwiftUI

struct PrimaryButton: View {
    let titleKey: LocalizedStringKey
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            action()
        }) {
            Text(titleKey, bundle: .main)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isEnabled ? DesignTokens.ink : DesignTokens.disabled)
                )
        }
        .buttonStyle(.plain)
        .allowsHitTesting(isEnabled)
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(isEnabled ? [] : .isButton)
    }
}
