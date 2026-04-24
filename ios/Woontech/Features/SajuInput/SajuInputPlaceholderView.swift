import SwiftUI

/// Legacy placeholder kept as a thin shim; the WF2 flow now lives in
/// `SajuInputFlowView`. The `SajuInputRoot` accessibility identifier has
/// been moved to the Step 1 container to avoid breaking OnboardingUITests.
struct SajuInputPlaceholderView: View {
    var body: some View {
        ZStack {
            DesignTokens.bg.ignoresSafeArea()

            VStack(spacing: 12) {
                Text("saju.placeholder.title", bundle: .main)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(DesignTokens.ink)

                Text("saju.placeholder.body", bundle: .main)
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.muted)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
    }
}
