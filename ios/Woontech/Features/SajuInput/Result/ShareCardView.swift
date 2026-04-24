import SwiftUI

/// 공유 카드 — Step 8 공유 + Step 10 미리보기 공용. FR-8.8 / FR-10.4.
struct ShareCardView: View {
    let result: SajuResultModel
    let displayNameLabel: String
    let dateLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(displayNameLabel)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DesignTokens.muted)

            Text(result.typeName)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(DesignTokens.ink)

            Text(result.dayPillarSummary)
                .font(.system(size: 14))
                .foregroundStyle(DesignTokens.ink)

            HStack(spacing: 8) {
                ForEach(result.wuxing, id: \.element) { bar in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(DesignTokens.ink)
                            .frame(width: 6, height: max(4, CGFloat(bar.value) * 40))
                        Text(bar.element.label)
                            .font(.system(size: 10))
                            .foregroundStyle(DesignTokens.muted)
                    }
                }
            }

            Text(result.oneLiner)
                .font(.system(size: 14))
                .foregroundStyle(DesignTokens.muted)

            Spacer()

            HStack {
                Text("운테크.app")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink)
                Spacer()
                Text(dateLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.muted)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignTokens.gray)
        )
        .accessibilityIdentifier("SajuShareCard")
    }

    static func todayLabel(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}
