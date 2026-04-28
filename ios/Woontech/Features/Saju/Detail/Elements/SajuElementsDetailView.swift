import SwiftUI

// MARK: - Sort Helper

/// provider.elements 배열을 [火, 木, 土, 金, 水] 고정 순서로 재정렬한다.
///
/// - Precondition: `elements.count == 5`. 길이가 5가 아니면 `preconditionFailure` 호출(AC#7).
///   비정상 경로(길이 ≠ 5)는 debug 빌드에서만 트랩 가능하므로 단위 테스트는
///   정상 경로(길이 5)만 검증하고 비정상 경로는 코드 리뷰 + 주석으로 갈음한다.
func sortedElements(_ elements: [ElementDistribution]) -> [ElementDistribution] {
    precondition(
        elements.count == 5,
        "SajuElementsDetailProviding.elements must contain exactly 5 items — got \(elements.count)"
    )
    let order = ["火", "木", "土", "金", "水"]
    let result = order.compactMap { sym in elements.first { $0.symbol == sym } }
    precondition(
        result.count == 5,
        "sortedElements: could not map all 5 symbols — ensure provider supplies [火,木,土,金,水]"
    )
    return result
}

// MARK: - Main View

/// 오행 분포 상세 화면 (WF4-04).
///
/// `SajuTabView` NavigationStack의 `.elements` 라우트 목적지.
/// provider는 `SajuElementsDetailProviding` 타입의 임의 mock으로 교체 가능(AC#13).
///
/// Identifier `SajuElementsDetailView`는 Color.clear 마커에 부여한다.
/// (ScrollView가 outermost이므로 `app.scrollViews` 대신 `app.otherElements` 쿼리를
/// 사용하기 위해 Color.clear 오버레이 패턴을 채택.)
struct SajuElementsDetailView: View {
    let provider: any SajuElementsDetailProviding

    private var sortedElems: [ElementDistribution] {
        sortedElements(provider.elements)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                SajuElementsSummaryCard(
                    headline: provider.summaryHeadline,
                    bodyText: provider.summaryBody
                )
                SajuElementsDistributionCard(elements: sortedElems)
                DisclaimerView()
                if let guidance = provider.guidance {
                    SajuElementsGuidanceCard(guidance: guidance)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(DesignTokens.bg)
        .navigationTitle(
            String(localized: "saju.elements.navTitle", defaultValue: "오행 분포")
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        // Hidden Color.clear root marker for UI tests.
        // Queried as app.otherElements["SajuElementsDetailView"].
        .overlay(alignment: .topLeading) {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityIdentifier("SajuElementsDetailView")
                .accessibilityHidden(false)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Summary Card

/// 오행 요약 카드 (최상단).
///
/// Identifier `ElementsSummaryCard` → `app.otherElements["ElementsSummaryCard"]`.
/// 자식 `ElementsSummaryHeadline` / `ElementsSummaryBody` → `app.staticTexts[...]`.
private struct SajuElementsSummaryCard: View {
    let headline: String
    /// `body`는 SwiftUI View.body 프로퍼티와 충돌하므로 `bodyText`로 명명.
    let bodyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "saju.elements.summary.sectionLabel", defaultValue: "오행 요약"))
                .font(.caption2)
                .foregroundStyle(DesignTokens.muted)

            Text(headline)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("ElementsSummaryHeadline")

            Text(bodyText)
                .font(.system(size: 10))
                .foregroundStyle(DesignTokens.muted)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("ElementsSummaryBody")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ElementsSummaryCard")
    }
}

// MARK: - Distribution Card

/// 5행 분포 바 차트 카드.
///
/// Identifier `ElementsDistributionCard` → `app.otherElements["ElementsDistributionCard"]`.
/// 각 행은 `ElementRow_\(symbol)` → `app.otherElements["ElementRow_火"]` 등.
private struct SajuElementsDistributionCard: View {
    /// sortedElements()로 이미 정렬된 배열을 받는다.
    let elements: [ElementDistribution]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "saju.elements.dist.sectionLabel", defaultValue: "5행 분포"))
                .font(.caption2)
                .foregroundStyle(DesignTokens.muted)

            ForEach(elements, id: \.symbol) { item in
                ElementDistributionRow(item: item)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ElementsDistributionCard")
    }
}

// MARK: - Distribution Row

/// 개별 원소 바 차트 행.
///
/// VoiceOver: isDeficient 행은 "부족, {koreanName} {symbol}, {note}, {count}점 8점 만점 중",
/// 일반 행은 "{koreanName} {symbol}, {note}, {count}점 8점 만점 중".
/// Identifier `ElementRow_\(symbol)` → `app.otherElements["ElementRow_火"]` 등.
private struct ElementDistributionRow: View {
    let item: ElementDistribution

    private var fillRatio: CGFloat {
        guard item.max > 0 else { return 0 }
        return CGFloat(item.count) / CGFloat(item.max)
    }

    private var fillColor: Color {
        if item.isDeficient { return DesignTokens.line2 }
        switch item.symbol {
        case "火": return DesignTokens.fireColor
        case "木": return DesignTokens.woodColor
        case "土": return DesignTokens.earthColor
        case "金": return DesignTokens.metalColor
        case "水": return DesignTokens.waterColor
        default:   return DesignTokens.ink
        }
    }

    private var accessibilityLabelText: String {
        let prefix = item.isDeficient ? "부족, " : ""
        return "\(prefix)\(item.koreanName) \(item.symbol), \(item.note), \(item.count)점 8점 만점 중"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline) {
                HStack(spacing: 4) {
                    Text(item.symbol)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DesignTokens.ink)
                    Text(item.koreanName)
                        .font(.system(size: 10))
                        .foregroundStyle(DesignTokens.muted)
                }
                Spacer()
                Text("\(item.note) · \(item.count)/8")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 막대 바 — 최소 높이 8pt (spec: 6pt 이상 유지)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DesignTokens.gray2)
                    Rectangle()
                        .fill(fillColor)
                        .frame(width: max(0, geometry.size.width * fillRatio))
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityIdentifier("ElementRow_\(item.symbol)")
    }
}

// MARK: - Guidance Card

/// 부족 원소 보완 가이드 카드.
///
/// `guidance != nil`일 때만 렌더된다(AC#8).
/// 레이아웃 순서: Summary → Distribution → Disclaimer → Guidance (AC#14 기준 채택).
/// AC#8의 "Disclaimer 앞" 명시와 상충하므로 AC#14 VoiceOver 순서를 우선 적용.
///
/// Identifier `ElementsGuidanceCard` → `app.otherElements["ElementsGuidanceCard"]`.
/// 헤더 `GuidanceHeader` → `app.staticTexts["GuidanceHeader"]`.
/// 각 bullet `GuidanceBullet_\(key)` → `app.otherElements["GuidanceBullet_direction"]` 등.
private struct SajuElementsGuidanceCard: View {
    let guidance: ElementGuidance

    private var headerText: String {
        String(
            format: String(
                localized: "saju.elements.guidance.headerFormat",
                defaultValue: "부족한 %@를 보완하려면"
            ),
            guidance.targetSymbol
        )
    }

    private var bullets: [(key: String, label: String, value: String)] {
        [
            (
                "direction",
                String(localized: "saju.elements.guidance.direction", defaultValue: "방향"),
                guidance.direction
            ),
            (
                "color",
                String(localized: "saju.elements.guidance.color", defaultValue: "색상"),
                guidance.color
            ),
            (
                "time",
                String(localized: "saju.elements.guidance.time", defaultValue: "시간"),
                guidance.time
            ),
            (
                "action",
                String(localized: "saju.elements.guidance.action", defaultValue: "행동"),
                guidance.action
            ),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(headerText)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("GuidanceHeader")

            VStack(alignment: .leading, spacing: 8) {
                ForEach(bullets, id: \.key) { bullet in
                    GuidanceBulletRow(key: bullet.key, label: bullet.label, value: bullet.value)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ElementsGuidanceCard")
    }
}

// MARK: - Guidance Bullet Row

/// 방향/색상/시간/행동 4개 bullet 중 하나.
///
/// VoiceOver: "{label} 보완: {value}".
/// Identifier `GuidanceBullet_\(key)` → `app.otherElements["GuidanceBullet_direction"]` 등.
private struct GuidanceBulletRow: View {
    let key: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(DesignTokens.ink)
                .frame(width: 4, height: 4)
                .padding(.top, 6)

            HStack(alignment: .top, spacing: 4) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.muted)
                Text("—")
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.muted)
                Text(value)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) 보완: \(value)")
        .accessibilityIdentifier("GuidanceBullet_\(key)")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SajuElementsDetailView(provider: MockSajuElementsDetailProvider())
    }
}

#Preview("No Guidance") {
    NavigationStack {
        SajuElementsDetailView(
            provider: MockSajuElementsDetailProvider(guidance: nil)
        )
    }
}
