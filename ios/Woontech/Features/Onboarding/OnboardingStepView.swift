import SwiftUI

struct OnboardingStepView: View {
    let step: Int

    private var content: OnboardingContent {
        OnboardingContent.all[step - 1]
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(content.illustrationAsset)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 140, height: 140)
                .foregroundStyle(DesignTokens.line2)
                .overlay(
                    Rectangle()
                        .stroke(DesignTokens.line2, lineWidth: 1)
                )
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(content.titleKey, bundle: .main)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DesignTokens.ink)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("OnboardingTitle_\(step)")

                Text(content.bodyKey, bundle: .main)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("OnboardingBody_\(step)")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(NSLocalizedString(content.titleAccessibilityKey, comment: "") + ". " + NSLocalizedString(content.bodyAccessibilityKey, comment: "")))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
