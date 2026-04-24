import SwiftUI

/// 사주 원국 미니 차트 — 4주(시/일/월/년). FR-8.2.2, FR-8.5.
struct SajuMiniChartView: View {
    let hourPillar: SajuPillar
    let dayPillar: SajuPillar
    let monthPillar: SajuPillar
    let yearPillar: SajuPillar
    let hourUnknown: Bool
    let metaLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("saju.result.origin.title", bundle: .main)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink)
                Spacer()
                Text("saju.result.origin.more", bundle: .main)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.muted)
                    .accessibilityIdentifier("SajuOriginMoreLink")
            }

            HStack(spacing: 8) {
                pillarColumn(columnName: "시",
                             pillar: hourPillar,
                             isUnknown: hourUnknown,
                             identifier: "SajuPillar_hour")
                pillarColumn(columnName: "일",
                             pillar: dayPillar,
                             isUnknown: false,
                             identifier: "SajuPillar_day")
                pillarColumn(columnName: "월",
                             pillar: monthPillar,
                             isUnknown: false,
                             identifier: "SajuPillar_month")
                pillarColumn(columnName: "년",
                             pillar: yearPillar,
                             isUnknown: false,
                             identifier: "SajuPillar_year")
            }

            Text(metaLabel)
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.muted)
                .accessibilityIdentifier("SajuOriginMeta")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
        .accessibilityIdentifier("SajuOriginChart")
    }

    @ViewBuilder
    private func pillarColumn(columnName: String,
                              pillar: SajuPillar,
                              isUnknown: Bool,
                              identifier: String) -> some View {
        VStack(spacing: 4) {
            Text(columnName)
                .font(.system(size: 10))
                .foregroundStyle(DesignTokens.muted)

            if isUnknown {
                VStack(spacing: 2) {
                    Text("—")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(DesignTokens.muted)
                    Text("—")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.muted)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            DesignTokens.gray2,
                            style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                        )
                )
                Text("saju.result.column.missing", bundle: .main)
                    .font(.system(size: 10))
                    .foregroundStyle(DesignTokens.muted)
                    .accessibilityIdentifier("\(identifier)_missing")
            } else {
                VStack(spacing: 2) {
                    Text(pillar.stem)
                        .font(.system(size: 16, weight: pillar.isDayPillar ? .bold : .regular))
                        .foregroundStyle(DesignTokens.ink)
                    Text(pillar.branch)
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.ink)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(pillar.isDayPillar ? DesignTokens.gray : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(DesignTokens.line3, lineWidth: 1)
                )
                Text(pillar.element)
                    .font(.system(size: 10))
                    .foregroundStyle(DesignTokens.muted)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text(isUnknown
                 ? "\(columnName) 미입력"
                 : "\(columnName) \(pillar.stem)\(pillar.branch) · \(pillar.element)")
        )
        .accessibilityIdentifier(identifier)
    }
}
