import SwiftUI

/// 사주 원국 카드 — 일간 쇼케이스 + 4주 그리드 + 오행 미니바 + 핵심 요약. FR-8.2.2, FR-8.5.
struct SajuMiniChartView: View {
    let hourPillar: SajuPillar
    let dayPillar: SajuPillar
    let monthPillar: SajuPillar
    let yearPillar: SajuPillar
    let hourUnknown: Bool
    let dayMasterNature: String
    let wuxing: [WuxingBar]
    let strongElements: [WuxingElement]
    let supplementElements: [WuxingElement]
    let investmentTags: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: 헤더
            Text("saju.result.origin.title", bundle: .main)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)

            Text("saju.result.origin.subtitle", bundle: .main)
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.muted)

            // MARK: 일간 쇼케이스 + 4주 그리드
            HStack(alignment: .top, spacing: 12) {
                dayMasterBox
                pillarGrid
            }

            // MARK: 오행 밸런스 미니바
            wuxingMiniBar
                .accessibilityIdentifier("SajuWuxingBlock")

            // MARK: 하단 요약
            summaryRow
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("SajuOriginChart")
    }

    // MARK: - 일간 쇼케이스 (왼쪽 다크 박스)

    private var dayMasterBox: some View {
        VStack(spacing: 6) {
            Text("saju.result.origin.me", bundle: .main)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)

            Text(dayPillar.stem)
                .font(.system(size: 38, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            Text("\(dayPillar.stemElement)·\(dayMasterNature)")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.6))
        }
        .frame(width: 80)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(DesignTokens.ink)
        )
        .accessibilityIdentifier("SajuDayMasterBox")
    }

    // MARK: - 4주 그리드

    private var pillarGrid: some View {
        let pillars: [(label: String, pillar: SajuPillar, isUnknown: Bool, id: String)] = [
            ("saju.result.column.yearPillar", yearPillar, false, "SajuPillar_year"),
            ("saju.result.column.monthPillar", monthPillar, false, "SajuPillar_month"),
            ("saju.result.column.dayPillar", dayPillar, false, "SajuPillar_day"),
            ("saju.result.column.hourPillar", hourPillar, hourUnknown, "SajuPillar_hour"),
        ]

        return HStack(spacing: 6) {
            ForEach(pillars, id: \.id) { item in
                VStack(spacing: 4) {
                    // 헤더
                    Text(LocalizedStringKey(item.label), bundle: .main)
                        .font(.system(size: 10))
                        .foregroundStyle(DesignTokens.muted)

                    // 천간
                    if item.isUnknown {
                        unknownCell
                    } else {
                        characterCell(
                            item.pillar.stem,
                            isDayPillar: item.pillar.isDayPillar,
                            fontSize: 18
                        )
                    }

                    // 지지
                    if item.isUnknown {
                        unknownCell
                    } else {
                        characterCell(
                            item.pillar.branch,
                            isDayPillar: item.pillar.isDayPillar,
                            fontSize: 18
                        )
                    }

                    // 오행 라벨
                    if item.isUnknown {
                        Text("saju.result.column.missing", bundle: .main)
                            .font(.system(size: 9))
                            .foregroundStyle(DesignTokens.muted)
                            .accessibilityIdentifier("\(item.id)_missing")
                    } else {
                        Text(item.pillar.elementLabel)
                            .font(.system(size: 9))
                            .foregroundStyle(DesignTokens.muted)
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(item.id)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 셀 헬퍼

    private func characterCell(_ char: String, isDayPillar: Bool, fontSize: CGFloat) -> some View {
        Text(char)
            .font(.system(size: fontSize, weight: isDayPillar ? .bold : .regular))
            .foregroundStyle(isDayPillar ? .white : DesignTokens.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isDayPillar ? DesignTokens.ink : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isDayPillar ? Color.clear : DesignTokens.line3, lineWidth: 1)
            )
    }

    private var unknownCell: some View {
        Text("—")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(DesignTokens.muted)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        DesignTokens.gray2,
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
            )
    }

    // MARK: - 오행 밸런스 미니바

    private var wuxingMiniBar: some View {
        let total = wuxing.reduce(0) { $0 + $1.value }

        return VStack(spacing: 6) {
            // 스택 바
            GeometryReader { proxy in
                HStack(spacing: 1) {
                    ForEach(wuxing, id: \.element) { bar in
                        if bar.value > 0 {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(bar.element.color)
                                .frame(width: max(4, proxy.size.width * bar.value / max(total, 1)))
                        }
                    }
                }
            }
            .frame(height: 6)
            .clipShape(RoundedRectangle(cornerRadius: 3))

            // 라벨
            HStack(spacing: 0) {
                ForEach(WuxingElement.allCases, id: \.self) { element in
                    Text(element.label)
                        .font(.system(size: 10))
                        .foregroundStyle(DesignTokens.muted)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - 하단 요약

    private var summaryRow: some View {
        HStack(alignment: .top, spacing: 0) {
            // 강한 기운
            VStack(alignment: .leading, spacing: 4) {
                Text("saju.result.origin.strong", bundle: .main)
                    .font(.system(size: 10))
                    .foregroundStyle(DesignTokens.muted)
                HStack(spacing: 4) {
                    ForEach(strongElements, id: \.self) { el in
                        elementDot(el)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 보완 기운
            VStack(alignment: .leading, spacing: 4) {
                Text("saju.result.origin.supplement", bundle: .main)
                    .font(.system(size: 10))
                    .foregroundStyle(DesignTokens.muted)
                HStack(spacing: 4) {
                    ForEach(supplementElements, id: \.self) { el in
                        elementDot(el)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 투자 성향
            VStack(alignment: .leading, spacing: 4) {
                Text("saju.result.origin.investmentStyle", bundle: .main)
                    .font(.system(size: 10))
                    .foregroundStyle(DesignTokens.muted)
                Text(investmentTags)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func elementDot(_ element: WuxingElement) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(element.color)
                .frame(width: 8, height: 8)
            Text(element.label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
        }
    }
}
