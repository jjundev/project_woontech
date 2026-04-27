import SwiftUI

// MARK: - Main View

struct InvestingAttitudeDetailView: View {
    let provider: any InvestingAttitudeDetailProviding
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Custom header with back button and title
            HStack(spacing: 16) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(DesignTokens.ink)
                }
                .accessibilityIdentifier("InvestingAttitudeDetailBackButton")

                Text("투자 태도")
                    .font(.headline)
                    .foregroundColor(DesignTokens.ink)
                    .accessibilityIdentifier("InvestingAttitudeDetailTitle")

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DesignTokens.bg)
            .border(DesignTokens.line3, width: 1)

            ScrollView {
                VStack(spacing: 24) {
                    // Score Circle
                    ScoreCircleView(score: clampAttitudeScore(provider.score))
                        .accessibilityIdentifier("AttitudeScore")

                    // Attitude Header
                    AttitudeHeaderView(
                        name: provider.attitudeName,
                        oneLiner: provider.oneLiner
                    )

                    // Breakdown Section (conditionally shown)
                    if !provider.breakdown.isEmpty {
                        BreakdownSectionView(breakdown: provider.breakdown)
                            .accessibilityIdentifier("BreakdownSection")
                    }

                    // Recommendations Section (conditionally shown)
                    if !provider.recommendations.isEmpty {
                        RecommendationsSectionView(recommendations: provider.recommendations)
                            .accessibilityIdentifier("RecommendationsSection")
                    }

                    // Disclaimer
                    DisclaimerView()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("InvestingAttitudeDetailView")
    }
}

// MARK: - Helper Function

private func clampAttitudeScore(_ score: Int) -> Int {
    return max(0, min(100, score))
}

// MARK: - Sub-Views

private struct ScoreCircleView: View {
    let score: Int

    var body: some View {
        VStack(spacing: 8) {
            Text("\(score)")
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(DesignTokens.ink)

            Text("/100")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(DesignTokens.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .accessibilityLabel("\(score)점")
    }
}

private struct AttitudeHeaderView: View {
    let name: String
    let oneLiner: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(DesignTokens.ink)
                .accessibilityIdentifier("AttitudeNameText")

            Text(oneLiner)
                .font(.caption)
                .foregroundColor(DesignTokens.muted)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("AttitudeOneliner")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BreakdownSectionView: View {
    let breakdown: [ScoreBreakdownItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("점수 구성")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignTokens.ink)

            VStack(spacing: 12) {
                ForEach(Array(breakdown.enumerated()), id: \.offset) { index, item in
                    ScoreBreakdownCardView(item: item, index: index)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .border(DesignTokens.line3)
        .cornerRadius(6)
    }
}

private struct ScoreBreakdownCardView: View {
    let item: ScoreBreakdownItem
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignTokens.ink)
                    .accessibilityIdentifier("BreakdownItemName_\(index)")

                Spacer()

                Text("\(clampBreakdownValue(item.value))점")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignTokens.ink)
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DesignTokens.line3)

                    Rectangle()
                        .fill(DesignTokens.waterColor)
                        .frame(width: geometry.size.width * CGFloat(clampBreakdownValue(item.value)) / 100.0)
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
            .accessibilityIdentifier("BreakdownItemBar_\(index)")

            Text(item.description)
                .font(.caption)
                .foregroundColor(DesignTokens.muted)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("BreakdownItemDescription_\(index)")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.name), \(clampBreakdownValue(item.value))점, \(item.description)")
        .accessibilityIdentifier("BreakdownItem_\(index)")
    }
}

private struct RecommendationsSectionView: View {
    let recommendations: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("추천 액션")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignTokens.ink)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(recommendations.enumerated()), id: \.offset) { index, recommendation in
                    RecommendationBulletView(text: recommendation, index: index)
                }
            }
            .accessibilityIdentifier("RecommendationsList")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .border(DesignTokens.line3)
        .cornerRadius(6)
    }
}

private struct RecommendationBulletView: View {
    let text: String
    let index: Int

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(DesignTokens.muted)
                .frame(width: 6, height: 6)
                .padding(.top, 7)

            Text(text)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(DesignTokens.ink)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityIdentifier("Recommendation_\(index)")
    }
}

// MARK: - Helper Functions

private func clampBreakdownValue(_ value: Int) -> Int {
    return max(0, min(100, value))
}

// MARK: - Preview

#Preview {
    NavigationStack {
        InvestingAttitudeDetailView(
            provider: MockInvestingAttitudeDetailProvider()
        )
    }
}
