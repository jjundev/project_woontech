import SwiftUI

// MARK: - Main View

struct TodayDetailView: View {
    let provider: any TodayDetailProviding
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Custom header (InvestingAttitudeDetailView 패턴과 일관)
            HStack(spacing: 16) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(DesignTokens.ink)
                }
                .accessibilityIdentifier("TodayDetailBackButton")

                Text("오늘의 일진")
                    .font(.headline)
                    .foregroundColor(DesignTokens.ink)
                    .accessibilityIdentifier("TodayDetailTitle")

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DesignTokens.bg)
            .border(DesignTokens.line3, width: 1)

            ScrollView {
                VStack(spacing: 16) {
                    SajuOriginCard(
                        chart: provider.sajuChart,
                        weakElement: provider.weakElement
                    )

                    SipseongCard(info: provider.sipseong)

                    if !provider.hapchungEvents.isEmpty {
                        HapchungCard(events: provider.hapchungEvents)
                    }

                    if let motto = provider.dailyMotto {
                        MottoCard(text: motto)
                    }

                    if let taboo = provider.dailyTaboo {
                        TabooCard(text: taboo)
                    }

                    DisclaimerView()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .accessibilityIdentifier("TodayDetailView")
    }
}

// MARK: - 사주 원국 카드

private struct SajuOriginCard: View {
    let chart: SajuChartData
    let weakElement: WuxingElement?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("나의 사주 원국")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignTokens.ink)
                Spacer()
                Text("일간(日干) = 나")
                    .font(.caption2)
                    .foregroundColor(DesignTokens.muted)
            }

            // SajuMiniChartView 재사용 (AC-15)
            SajuMiniChartView(
                hourPillar: chart.hourPillar,
                dayPillar: chart.dayPillar,
                monthPillar: chart.monthPillar,
                yearPillar: chart.yearPillar,
                hourUnknown: chart.hourUnknown,
                dayMasterNature: chart.dayMasterNature,
                wuxing: Self.makeWuxingBars(from: chart.elementCounts),
                strongElements: Self.computeStrongElements(from: chart.elementCounts),
                supplementElements: Self.computeSupplementElements(from: chart.elementCounts),
                investmentTags: chart.investmentTags
            )

            WuxingDistributionRow(elementCounts: chart.elementCounts, weakElement: weakElement)

            if let weak = weakElement {
                Text("\(weak.hanja) 부족 → \(weak.hanja) 기운의 날 주의")
                    .font(.caption)
                    .foregroundColor(DesignTokens.fireColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("WuxingWarningText")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
        .accessibilityIdentifier("SajuOriginCard")
    }

    /// 카운트(0~) → 0.0~1.0 정규화한 `WuxingBar` 배열.
    static func makeWuxingBars(from counts: [WuxingElement: Int]) -> [WuxingBar] {
        let total = max(counts.values.reduce(0, +), 1)
        return WuxingElement.allCases.map { element in
            let count = counts[element] ?? 0
            return WuxingBar(element: element, value: Double(count) / Double(total))
        }
    }

    static func computeStrongElements(from counts: [WuxingElement: Int]) -> [WuxingElement] {
        WuxingElement.allCases.filter { (counts[$0] ?? 0) >= 3 }
    }

    static func computeSupplementElements(from counts: [WuxingElement: Int]) -> [WuxingElement] {
        WuxingElement.allCases.filter { (counts[$0] ?? 0) == 0 }
    }
}

// MARK: - 오행 분포 행 (5칸: 한글·한자·숫자)

private struct WuxingDistributionRow: View {
    let elementCounts: [WuxingElement: Int]
    let weakElement: WuxingElement?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("오행 분포")
                .font(.caption2)
                .foregroundColor(DesignTokens.muted)

            HStack(alignment: .top, spacing: 4) {
                ForEach(WuxingElement.allCases, id: \.self) { element in
                    let count = elementCounts[element] ?? 0
                    let isZero = count == 0
                    VStack(spacing: 2) {
                        Text(element.label)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(DesignTokens.ink)
                        Text(element.hanja)
                            .font(.system(size: 9, design: .serif))
                            .foregroundColor(DesignTokens.muted)
                        Text("\(count)")
                            .font(.caption2)
                            .foregroundColor(isZero ? DesignTokens.fireColor : DesignTokens.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("WuxingCell_\(element.rawValue)")
                    .accessibilityLabel("\(element.label) \(element.hanja) \(count)")
                }
            }
        }
        .padding(8)
        .background(DesignTokens.gray)
        .cornerRadius(4)
    }
}

// MARK: - 십성 카드

private struct SipseongCard: View {
    let info: SipseongInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("오늘의 십성(十星)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignTokens.ink)

            Text("십성: 내 사주와 오늘의 기운이 어떤 관계로 만나는지")
                .font(.caption2)
                .foregroundColor(DesignTokens.muted)

            HStack(alignment: .center, spacing: 12) {
                // 좌측 stamp (검정 56×56)
                VStack(spacing: 2) {
                    Text(info.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .accessibilityIdentifier("SipseongStampName")
                    Text(info.hanja)
                        .font(.system(size: 9, design: .serif))
                        .foregroundColor(Color.white.opacity(0.7))
                        .accessibilityIdentifier("SipseongStampHanja")
                }
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DesignTokens.ink)
                )

                // 우측 3줄
                VStack(alignment: .leading, spacing: 4) {
                    Text(info.oneLiner)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(DesignTokens.ink)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("SipseongOneLiner")
                    Text(info.relation)
                        .font(.caption)
                        .foregroundColor(DesignTokens.muted)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("SipseongRelation")
                    Text(info.examples)
                        .font(.caption2)
                        .foregroundColor(DesignTokens.muted)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("SipseongExamples")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
        .accessibilityIdentifier("SipseongCard")
    }
}

// MARK: - 합충 카드

private struct HapchungCard: View {
    let events: [HapchungEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("오늘의 합충(合沖)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignTokens.ink)
                Spacer()
                Text("합(+) · 충(−)")
                    .font(.caption2)
                    .foregroundColor(DesignTokens.muted)
            }

            VStack(spacing: 8) {
                ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                    HapchungRowView(event: event, index: index)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("HapchungSection")
    }
}

// MARK: - 합충 row

private struct HapchungRowView: View {
    let event: HapchungEvent
    let index: Int

    private var isNegative: Bool { event.impact == .negative }
    private var symbol: String { isNegative ? "↔" : "+" }
    private var primaryColor: Color { isNegative ? DesignTokens.fireColor : DesignTokens.ink }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                branchBox(event.branch1)

                Text(symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryColor)

                branchBox(event.branch2)

                kindBadge

                Spacer(minLength: 4)

                Text(TodayDetailFormatting.formattedScore(event.score))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(primaryColor)
                    .lineLimit(1)
                    .layoutPriority(1)
                    .fixedSize()
                    .accessibilityIdentifier("HapchungRow_\(index)_Score")
            }

            if let note = event.note {
                Text(note)
                    .font(.caption2)
                    .foregroundColor(isNegative ? DesignTokens.fireColor : DesignTokens.muted)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 비주얼 검증을 위한 invisible 식별자 (AC-9)
            if isNegative {
                Color.clear
                    .frame(width: 0, height: 0)
                    .accessibilityIdentifier("HapchungRow_\(index)_NegativeStyle")
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    primaryColor,
                    style: isNegative
                        ? StrokeStyle(lineWidth: 1, dash: [4, 3])
                        : StrokeStyle(lineWidth: 1)
                )
        )
        // children: .contain — 컨테이너로 노출하면서 내부 식별자(`HapchungRow_<index>_Score`,
        // `HapchungRow_<index>_NegativeStyle`)도 XCUITest 쿼리 가능 (.ignore는 children을 collapse).
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(event.branch1.hanja) \(symbol) \(event.branch2.hanja), \(event.kind), \(event.score)점")
        .accessibilityIdentifier("HapchungRow_\(index)")
    }

    private func branchBox(_ branch: HapchungBranch) -> some View {
        VStack(spacing: 2) {
            Text(branch.hanja)
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundColor(primaryColor)
            Text(branch.hangul)
                .font(.system(size: 8))
                .foregroundColor(isNegative ? DesignTokens.fireColor : DesignTokens.muted)
        }
        .frame(width: 36, height: 36)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isNegative ? DesignTokens.fireColor : DesignTokens.line3, lineWidth: 1)
        )
    }

    private var kindBadge: some View {
        Text(event.kind)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(isNegative ? DesignTokens.fireColor : .white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(isNegative ? Color.clear : DesignTokens.ink)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isNegative ? DesignTokens.fireColor : DesignTokens.ink, lineWidth: 1)
            )
            .fixedSize()
    }
}

// MARK: - 옵션 카드

private struct MottoCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("오늘의 한마디")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignTokens.ink)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(DesignTokens.ink)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.gray)
        .cornerRadius(6)
        .accessibilityIdentifier("DailyMottoCard")
    }
}

private struct TabooCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("오늘의 금기")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignTokens.fireColor)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(DesignTokens.ink)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignTokens.fireColor, lineWidth: 1)
        )
        .accessibilityIdentifier("DailyTabooCard")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TodayDetailView(provider: MockTodayDetailProvider())
    }
}
