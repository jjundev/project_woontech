import SwiftUI

struct ProTeaserCard: View {
    let provider: any WeeklyEventsProviding
    let onProTrialTap: () -> Void

    private var proFeatures: [String] {
        provider.proFeatures()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                // Header with lock icon
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignTokens.ink)

                    Text("PRO로 더 깊은 분석")
                        .font(.system(size: 12, weight: .bold))

                    Spacer()
                }

                // Feature list
                if !proFeatures.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(proFeatures, id: \.self) { feature in
                            HStack(alignment: .center, spacing: 6) {
                                Circle()
                                    .fill(DesignTokens.line2)
                                    .frame(width: 14, height: 14)
                                    .overlay(
                                        Text("›")
                                            .font(.system(size: 7, weight: .semibold))
                                            .foregroundStyle(DesignTokens.muted)
                                    )

                                Text(feature)
                                    .font(.caption)
                                    .foregroundStyle(DesignTokens.muted)
                                    .lineLimit(2)

                                Spacer()
                            }
                        }
                    }
                }

                // Trial button
                Button(action: onProTrialTap) {
                    Text("7일 무료 체험 →")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(DesignTokens.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .accessibilityIdentifier("ProTeaserTrialButton")
            }
            .padding(12)
        }
        .background(Color.white)
        .border(DesignTokens.line2, width: 1)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .accessibilityIdentifier("ProTeaserCard")
    }
}

#Preview {
    ProTeaserCard(
        provider: MockWeeklyEventsProvider(),
        onProTrialTap: {}
    )
}
