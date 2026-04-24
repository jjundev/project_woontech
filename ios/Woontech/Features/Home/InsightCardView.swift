import SwiftUI

// MARK: - Single Insight Card

struct InsightCardView: View {
    let card: InsightCard
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 상단 badge pill
                Text(card.badgeLabel)
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(card.badgeColor)
                    .clipShape(Capsule())

                // 아이콘 (large)
                Image(systemName: card.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(card.badgeColor)

                // title bold
                Text(card.title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)

                // desc multiline (\n 유지)
                Text(card.desc)
                    .font(.caption)
                    .foregroundStyle(DesignTokens.muted)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 4)

                // 하단 캡션
                Text(card.bottomLabel)
                    .font(.caption2)
                    .foregroundStyle(DesignTokens.muted)
            }
            .padding(12)
            .frame(width: 160)
            .background(DesignTokens.gray)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(card.badgeLabel), \(card.title)")
    }
}

// MARK: - Empty Placeholder Card (AC-14)

private struct InsightPlaceholderCard: View {
    let index: Int

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(DesignTokens.gray)
            .frame(width: 160, height: 200)
            .accessibilityIdentifier("InsightCard_empty_\(index)")
    }
}

// MARK: - Insights Horizontal Scroll View

struct InsightsScrollView: View {
    let provider: any InsightsProviding
    let onTabooTap: () -> Void
    let onTodayTap: () -> Void
    let onPracticeTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("오늘의 인사이트")
                .font(.headline)
                .padding(.horizontal, 16)
                .accessibilityIdentifier("HomeInsightsSectionLabel")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // 슬롯 0: 금기 (고정 순서)
                    if let card = provider.cards[safe: 0] {
                        InsightCardView(card: card, onTap: onTabooTap)
                            .accessibilityIdentifier("HomeInsightsCard_0")
                    } else {
                        InsightPlaceholderCard(index: 0)
                    }

                    // 슬롯 1: 일진 (고정 순서)
                    if let card = provider.cards[safe: 1] {
                        InsightCardView(card: card, onTap: onTodayTap)
                            .accessibilityIdentifier("HomeInsightsCard_1")
                    } else {
                        InsightPlaceholderCard(index: 1)
                    }

                    // 슬롯 2: 실천 (고정 순서)
                    if let card = provider.cards[safe: 2] {
                        InsightCardView(card: card, onTap: onPracticeTap)
                            .accessibilityIdentifier("HomeInsightsCard_2")
                    } else {
                        InsightPlaceholderCard(index: 2)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.top, 16)
    }
}
