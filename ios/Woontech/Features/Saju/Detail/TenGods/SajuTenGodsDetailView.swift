import SwiftUI

// MARK: - Validation Errors

/// 십성 분석 상세 데이터 검증 오류.
enum TenGodsValidationError: Error {
    case invalidGroupCount(Int)
    case invalidItemsLength(name: String)
    case invalidTopThreeCount(Int)
}

// MARK: - Validation Helpers (testable)

/// groups 배열 길이가 5인지 검증한다.
///
/// XCTest(`@testable import`)에서 `XCTAssertThrowsError`로 호출 가능.
/// 프로덕션 코드는 이 함수 호출 후 `precondition`으로 이중 방어한다.
internal func validateGroups(_ groups: [TenGodGroup]) throws {
    guard groups.count == 5 else {
        throw TenGodsValidationError.invalidGroupCount(groups.count)
    }
}

/// 각 TenGodGroup의 items/counts 길이가 2인지 검증한다.
///
/// XCTest에서 `XCTAssertThrowsError`로 호출 가능.
internal func validateGroupLengths(_ groups: [TenGodGroup]) throws {
    for g in groups {
        guard g.items.count == 2, g.counts.count == 2 else {
            throw TenGodsValidationError.invalidItemsLength(name: g.name)
        }
    }
}

/// topThree 배열 길이가 3인지 검증한다.
///
/// XCTest에서 `XCTAssertThrowsError`로 호출 가능.
internal func validateTopThree(_ topThree: [CoreTenGod]) throws {
    guard topThree.count == 3 else {
        throw TenGodsValidationError.invalidTopThreeCount(topThree.count)
    }
}

// MARK: - Sort Helper

/// groups 배열을 [비겁, 식상, 재성, 관성, 인성] 고정 순서로 재정렬한다.
///
/// - Precondition: `groups.count == 5`. 길이가 5가 아니거나
///   정렬 후 결과가 5가 아니면 `preconditionFailure` 호출.
func sortedTenGodGroups(_ groups: [TenGodGroup]) -> [TenGodGroup] {
    try? validateGroups(groups)  // throws-based check (testable)
    precondition(
        groups.count == 5,
        "SajuTenGodsDetailProviding.groups must contain exactly 5 items — got \(groups.count)"
    )
    let order = ["비겁", "식상", "재성", "관성", "인성"]
    let result = order.compactMap { name in groups.first { $0.name == name } }
    precondition(
        result.count == 5,
        "sortedTenGodGroups: could not map all 5 groups — ensure provider supplies [비겁,식상,재성,관성,인성]"
    )
    return result
}

// MARK: - Display Helpers

/// `counts[i] > 0`인 items만 " · "로 join 반환. 전부 0이면 "—".
internal func displayedItems(items: [String], counts: [Int]) -> String {
    let active = zip(items, counts).compactMap { name, count in count > 0 ? name : nil }
    return active.isEmpty ? "—" : active.joined(separator: " · ")
}

/// 막대 채움 비율. `min(total / 3.0, 1.0)`.
internal func tenGodsFillRatio(total: Int) -> CGFloat {
    min(CGFloat(total) / 3.0, 1.0)
}

// MARK: - Main View

/// 십성 분석 상세 화면 (WF4-05).
///
/// `SajuTabView` NavigationStack의 `.tenGods` 라우트 목적지.
/// `provider`는 임의 mock으로 교체 가능 (AC#17).
/// `onNavigate`는 학습 유도 카드 탭 시 `SajuRoute.lesson(id:)` push에 사용.
///
/// Root identifier `SajuTenGodsDetailView`는 Color.clear 마커에 부여한다
/// (ScrollView가 outermost이므로 `app.otherElements` 쿼리를 위해 Color.clear 패턴 채택).
struct SajuTenGodsDetailView: View {
    let provider: any SajuTenGodsDetailProviding
    let onNavigate: (SajuRoute) -> Void

    private var sortedGroups: [TenGodGroup] {
        sortedTenGodGroups(provider.groups)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                TenGodsSummaryCard(
                    headline: provider.summaryHeadline,
                    bodyText: provider.summaryBody
                )

                TenGodsDistributionCard(groups: sortedGroups)

                TenGodsCoreSection(topThree: provider.topThree)

                if let warning = provider.absentWarning {
                    TenGodsAbsentWarningCard(warning: warning)
                }

                if let entry = provider.learnEntry {
                    TenGodsLearnEntryCard(entry: entry, onTap: {
                        onNavigate(.lesson(id: entry.lessonId))
                    })
                }

                DisclaimerView()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(DesignTokens.bg)
        .navigationTitle(
            String(localized: "saju.tengods.navTitle", defaultValue: "십성 분석")
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        // Hidden Color.clear root marker for UI tests.
        // Queried as app.otherElements["SajuTenGodsDetailView"].
        .overlay(alignment: .topLeading) {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityIdentifier("SajuTenGodsDetailView")
                .accessibilityHidden(false)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Summary Card

/// 십성 요약 카드 (최상단).
///
/// Identifier `TenGodsSummaryCard` → `app.otherElements["TenGodsSummaryCard"]`.
/// 자식: `TenGodsSummaryHeadline` / `TenGodsSummaryBody` → `app.staticTexts[...]`.
private struct TenGodsSummaryCard: View {
    let headline: String
    let bodyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "saju.tengods.summary.sectionLabel", defaultValue: "십성 요약"))
                .font(.caption2)
                .foregroundStyle(DesignTokens.muted)

            Text(headline)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("TenGodsSummaryHeadline")

            Text(bodyText)
                .font(.system(size: 10))
                .foregroundStyle(DesignTokens.muted)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("TenGodsSummaryBody")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("TenGodsSummaryCard")
    }
}

// MARK: - Distribution Card

/// 5그룹 분포 바 차트 카드.
///
/// Identifier `TenGodsDistributionCard` → `app.otherElements["TenGodsDistributionCard"]`.
/// 각 행: `TenGodsGroupRow_{name}` → `app.otherElements["TenGodsGroupRow_비겁"]` 등.
private struct TenGodsDistributionCard: View {
    let groups: [TenGodGroup]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "saju.tengods.dist.sectionLabel", defaultValue: "5그룹 분포"))
                .font(.caption2)
                .foregroundStyle(DesignTokens.muted)
                .padding(.bottom, 10)

            VStack(spacing: 12) {
                ForEach(groups, id: \.name) { group in
                    TenGodsGroupRow(group: group)
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
        .accessibilityIdentifier("TenGodsDistributionCard")
    }
}

// MARK: - Group Row

/// 개별 그룹 분포 행.
///
/// VoiceOver:
/// - 기본: `"{name} {han}, {meaning}, {total}점 8점 만점 중"`
/// - isCore: "핵심, " 접두어 추가
/// - isAbsent: "부재 경고, " 접두어 추가
///
/// Identifier `TenGodsGroupRow_{name}` → `app.otherElements["TenGodsGroupRow_비겁"]`.
/// 하위: `TenGodsDisplayedItems_{name}` → `app.staticTexts["TenGodsDisplayedItems_비겁"]`.
/// 하위(isCore): `TenGodsCoreBadge_{name}` → `app.staticTexts["TenGodsCoreBadge_재성"]`.
private struct TenGodsGroupRow: View {
    let group: TenGodGroup

    private var fillRatio: CGFloat {
        tenGodsFillRatio(total: group.total)
    }

    private var barFillColor: Color {
        group.isAbsent ? DesignTokens.line2 : DesignTokens.ink
    }

    private var displayedItemsText: String {
        displayedItems(items: group.items, counts: group.counts)
    }

    private var accessibilityLabelText: String {
        var prefix = ""
        if group.isAbsent { prefix = "부재 경고, " }
        else if group.isCore { prefix = "핵심, " }
        return "\(prefix)\(group.name) \(group.han), \(group.meaning), \(group.total)점 8점 만점 중"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 상단 HStack: 이름/한자/핵심 배지 + 우측 메타
            HStack(alignment: .lastTextBaseline) {
                HStack(spacing: 4) {
                    Text(group.name)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DesignTokens.ink)
                    Text(group.han)
                        .font(.system(.caption2, design: .serif))
                        .foregroundStyle(DesignTokens.muted)
                    if group.isCore {
                        Text("핵심")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(DesignTokens.coreBadgeBg)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .accessibilityIdentifier("TenGodsCoreBadge_\(group.name)")
                    }
                }
                Spacer()
                if group.isAbsent {
                    Text("부재 ⚠")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.absentRed)
                } else {
                    Text("\(group.total)/8")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.muted)
                }
            }

            // 막대 바 (높이 7pt)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DesignTokens.gray2)
                    Rectangle()
                        .fill(barFillColor)
                        .frame(width: max(0, geometry.size.width * fillRatio))
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(height: 7)

            // 보조 라인: 의미(좌) + 표출 십성(우)
            HStack {
                Text(group.meaning)
                    .font(.system(size: 9))
                    .foregroundStyle(DesignTokens.muted)
                Spacer()
                Text(displayedItemsText)
                    .font(.system(size: 9))
                    .foregroundStyle(DesignTokens.muted)
                    .accessibilityIdentifier("TenGodsDisplayedItems_\(group.name)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityIdentifier("TenGodsGroupRow_\(group.name)")
    }
}

// MARK: - Core Section

/// 나의 핵심 십성 섹션.
///
/// `topThree.count != 3` 시 preconditionFailure.
/// Identifier `TenGodsCoreSection` → `app.otherElements["TenGodsCoreSection"]`.
private struct TenGodsCoreSection: View {
    let topThree: [CoreTenGod]

    var body: some View {
        let _ = {
            try? validateTopThree(topThree)
            precondition(
                topThree.count == 3,
                "SajuTenGodsDetailProviding.topThree must contain exactly 3 items — got \(topThree.count)"
            )
        }()

        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "saju.tengods.core.sectionLabel", defaultValue: "나의 핵심 십성"))
                .font(.caption2)
                .foregroundStyle(DesignTokens.muted)
                .padding(.bottom, 10)

            VStack(spacing: 10) {
                ForEach(Array(topThree.enumerated()), id: \.offset) { index, god in
                    TenGodsCoreCard(god: god, index: index, isFirst: index == 0)
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
        .accessibilityIdentifier("TenGodsCoreSection")
    }
}

// MARK: - Core Card

/// 핵심 십성 카드 (한 장).
///
/// VoiceOver: `"{name} {han}, {count}회, {meaning}. 투자 함의: {investImplication}"`.
/// Identifier `TenGodsCoreCard_{index}` → `app.otherElements["TenGodsCoreCard_0"]`.
/// 투자 함의 박스: `TenGodsInvestImplication_{index}` → `app.staticTexts["TenGodsInvestImplication_0"]`.
private struct TenGodsCoreCard: View {
    let god: CoreTenGod
    let index: Int
    let isFirst: Bool

    private var a11yLabel: String {
        "\(god.name) \(god.han), \(god.count)회, \(god.meaning). 투자 함의: \(god.investImplication)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 상단 HStack: 이름/한자 + ×count
            HStack(alignment: .lastTextBaseline) {
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    Text(god.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DesignTokens.ink)
                    Text(god.han)
                        .font(.system(.caption2, design: .serif))
                        .foregroundStyle(DesignTokens.muted)
                }
                Spacer()
                Text("×\(god.count)")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.muted)
            }
            .padding(.bottom, 3)

            // 본문 의미
            Text(god.meaning)
                .font(.system(size: 10))
                .foregroundStyle(DesignTokens.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 7)

            // 투자 함의 박스
            HStack(spacing: 6) {
                Text("💹")
                    .font(.system(size: 11))
                Text(god.investImplication)
                    .font(.system(size: 9))
                    .foregroundStyle(DesignTokens.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("TenGodsInvestImplication_\(index)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(DesignTokens.gray2)
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isFirst ? DesignTokens.gray : DesignTokens.bg)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFirst ? DesignTokens.line2 : DesignTokens.line3, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(a11yLabel)
        .accessibilityIdentifier("TenGodsCoreCard_\(index)")
    }
}

// MARK: - Absent Warning Card

/// 부재 십성 경고 카드.
///
/// `absentWarning != nil`일 때만 렌더된다(AC#12, AC#13).
/// VoiceOver: `"주의, 부재 십성, {groupTitle}. {copy}"`.
/// Identifier `TenGodsAbsentWarningCard` → `app.otherElements["TenGodsAbsentWarningCard"]`.
/// Copy 박스: `TenGodsAbsentWarningCopy` → `app.staticTexts["TenGodsAbsentWarningCopy"]`.
private struct TenGodsAbsentWarningCard: View {
    let warning: AbsentWarning

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "saju.tengods.absent.sectionLabel", defaultValue: "주의 — 부재 십성"))
                .font(.caption2)
                .foregroundStyle(DesignTokens.absentRed)

            Text(warning.groupTitle)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)

            // copy 박스 (연한 빨강 배경)
            Text(warning.copy)
                .font(.system(size: 10))
                .foregroundStyle(DesignTokens.muted)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(DesignTokens.absentRedLight)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .accessibilityIdentifier("TenGodsAbsentWarningCopy")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignTokens.absentRed, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("주의, 부재 십성, \(warning.groupTitle). \(warning.copy)")
        .accessibilityIdentifier("TenGodsAbsentWarningCard")
    }
}

// MARK: - Learn Entry Card

/// 학습 유도 카드.
///
/// `learnEntry != nil`일 때만 렌더된다(AC#14, AC#15).
/// 탭 시 `onNavigate(.lesson(id: entry.lessonId))` 호출.
/// VoiceOver: `"레슨 진입, {title}, {durationLabel}, {levelLabel}"`.
/// Identifier `TenGodsLearnEntryCard` → `app.buttons["TenGodsLearnEntryCard"]`.
private struct TenGodsLearnEntryCard: View {
    let entry: LearnEntry
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text("📚")
                    .font(.system(size: 22))

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignTokens.ink)
                    Text("\(entry.durationLabel) 레슨 · \(entry.levelLabel)")
                        .font(.caption2)
                        .foregroundStyle(DesignTokens.muted)
                }

                Spacer()

                Text("›")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(DesignTokens.line3, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "레슨 진입, \(entry.title), \(entry.durationLabel), \(entry.levelLabel)"
        )
        .accessibilityIdentifier("TenGodsLearnEntryCard")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SajuTenGodsDetailView(
            provider: MockSajuTenGodsDetailProvider(),
            onNavigate: { _ in }
        )
    }
}

#Preview("No Absent Warning") {
    NavigationStack {
        SajuTenGodsDetailView(
            provider: MockSajuTenGodsDetailProvider(absentWarning: nil),
            onNavigate: { _ in }
        )
    }
}

#Preview("No Learn Entry") {
    NavigationStack {
        SajuTenGodsDetailView(
            provider: MockSajuTenGodsDetailProvider(learnEntry: nil),
            onNavigate: { _ in }
        )
    }
}
