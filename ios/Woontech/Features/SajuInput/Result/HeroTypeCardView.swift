import SwiftUI

/// Hero 유형 카드 — "{이름}님의 투자 성향" + 유형명 + 일주/십성 + 한 줄. FR-8.2.1.
struct HeroTypeCardView: View {
    let label: String
    let typeName: String
    let dayPillarSummary: String
    let oneLiner: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DesignTokens.muted)
                .accessibilityIdentifier("SajuHeroLabel")

            Text(typeName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
                .accessibilityIdentifier("SajuHeroTypeName")

            Text(dayPillarSummary)
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.ink)

            Text(oneLiner)
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.gray)
        )
        .accessibilityIdentifier("SajuHeroCard")
    }
}
