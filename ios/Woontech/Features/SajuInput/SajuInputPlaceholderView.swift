import SwiftUI

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
        .accessibilityIdentifier("SajuInputRoot")
    }
}
