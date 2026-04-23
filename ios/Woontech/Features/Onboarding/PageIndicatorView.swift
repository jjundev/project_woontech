import SwiftUI

struct PageIndicatorView: View {
    let current: Int
    let total: Int
    let onTap: (Int) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...total, id: \.self) { index in
                Button {
                    onTap(index)
                } label: {
                    dot(for: index)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(String(format: NSLocalizedString("onboarding.indicator.label", comment: ""), index)))
                .accessibilityAddTraits(index == current ? .isSelected : [])
                .accessibilityIdentifier("OnboardingIndicator_\(index)")
            }
        }
        .frame(height: 44)
        .accessibilityIdentifier("OnboardingIndicatorRow")
    }

    @ViewBuilder
    private func dot(for index: Int) -> some View {
        let isActive = index == current
        RoundedRectangle(cornerRadius: 3)
            .fill(isActive ? DesignTokens.ink : DesignTokens.gray2)
            .frame(width: isActive ? 16 : 6, height: 6)
    }
}
