import Foundation

// MARK: - Data Models

/// 오늘의 일진 상세 카드에서 사주 원국을 렌더하기 위한 데이터.
/// 4기둥(년·월·일·시) + 오행 카운트 + `SajuMiniChartView` 재사용을 위한 보조 필드.
struct SajuChartData: Equatable {
    var yearPillar: SajuPillar
    var monthPillar: SajuPillar
    var dayPillar: SajuPillar          // 일간(나)
    var hourPillar: SajuPillar
    var hourUnknown: Bool
    var dayMasterNature: String        // 예: "강철" — SajuMiniChartView 재사용
    var investmentTags: String         // 재사용을 위한 placeholder
    var elementCounts: [WuxingElement: Int]  // 목·화·토·금·수 카운트(0~)
}

enum HapchungImpact: Equatable {
    case positive
    case negative
}

struct HapchungBranch: Equatable {
    let hanja: String   // "申"
    let hangul: String  // "신금"
}

struct HapchungEvent: Identifiable, Equatable {
    let id: UUID
    let branch1: HapchungBranch
    let branch2: HapchungBranch
    let kind: String           // "육합", "월지충"
    let impact: HapchungImpact
    let score: Int             // 부호 그대로(예: 12, -18)
    let note: String?

    init(
        id: UUID = UUID(),
        branch1: HapchungBranch,
        branch2: HapchungBranch,
        kind: String,
        impact: HapchungImpact,
        score: Int,
        note: String? = nil
    ) {
        self.id = id
        self.branch1 = branch1
        self.branch2 = branch2
        self.kind = kind
        self.impact = impact
        self.score = score
        self.note = note
    }
}

struct SipseongInfo: Equatable {
    let name: String       // "편관"
    let hanja: String      // "偏官"
    let oneLiner: String
    let relation: String
    let examples: String
}

// MARK: - WuxingElement helpers used by Today detail

extension WuxingElement {
    /// 오행 한자 표기 (목→木, 화→火, 토→土, 금→金, 수→水).
    var hanja: String {
        switch self {
        case .wood:  return "木"
        case .fire:  return "火"
        case .earth: return "土"
        case .metal: return "金"
        case .water: return "水"
        }
    }
}

// MARK: - Protocol

protocol TodayDetailProviding {
    var sajuChart: SajuChartData { get }
    var weakElement: WuxingElement? { get }   // 0개인 오행
    var sipseong: SipseongInfo { get }
    var hapchungEvents: [HapchungEvent] { get }
    var dailyMotto: String? { get }
    var dailyTaboo: String? { get }
}

// MARK: - Mock Implementation

struct MockTodayDetailProvider: TodayDetailProviding {
    var sajuChart: SajuChartData
    var weakElement: WuxingElement?
    var sipseong: SipseongInfo
    var hapchungEvents: [HapchungEvent]
    var dailyMotto: String?
    var dailyTaboo: String?

    init(
        sajuChart: SajuChartData? = nil,
        weakElement: WuxingElement? = nil,
        sipseong: SipseongInfo? = nil,
        hapchungEvents: [HapchungEvent]? = nil,
        dailyMotto: String? = nil,
        dailyTaboo: String? = nil
    ) {
        let resolvedChart = sajuChart ?? Self.defaultSajuChart
        self.sajuChart = resolvedChart
        // weakElement: 명시값이 있으면 그대로, 아니면 카운트 0인 오행을 자동으로 도출.
        if let explicit = weakElement {
            self.weakElement = explicit
        } else {
            // WuxingElement.allCases 순서로 0인 첫 원소를 찾는다 — 와이어프레임 기본 mock은 .water.
            self.weakElement = WuxingElement.allCases.first {
                (resolvedChart.elementCounts[$0] ?? 0) == 0
            }
        }
        self.sipseong = sipseong ?? Self.defaultSipseong
        self.hapchungEvents = hapchungEvents ?? Self.defaultHapchungEvents
        self.dailyMotto = dailyMotto
        self.dailyTaboo = dailyTaboo
    }

    // MARK: - Default fixtures (WF3-06 spec §4)

    static let defaultSajuChart: SajuChartData = SajuChartData(
        yearPillar: SajuPillar(
            stem: "庚", branch: "午",
            stemElement: "금", branchElement: "화",
            isDayPillar: false
        ),
        monthPillar: SajuPillar(
            stem: "己", branch: "卯",
            stemElement: "토", branchElement: "목",
            isDayPillar: false
        ),
        dayPillar: SajuPillar(
            stem: "庚", branch: "申",
            stemElement: "금", branchElement: "금",
            isDayPillar: true
        ),
        hourPillar: SajuPillar(
            stem: "丁", branch: "巳",
            stemElement: "화", branchElement: "화",
            isDayPillar: false
        ),
        hourUnknown: false,
        dayMasterNature: "강철",
        investmentTags: "원칙형 · 관리형",
        elementCounts: [
            .wood: 1,
            .fire: 3,
            .earth: 1,
            .metal: 3,
            .water: 0
        ]
    )

    static let defaultSipseong: SipseongInfo = SipseongInfo(
        name: "편관",
        hanja: "偏官",
        oneLiner: "갑작스러운 압박의 날",
        relation: "내 일간(경·金)을 압박하는 기운",
        examples: "업무 과중 · 극적 승진 · 위험 감수"
    )

    static let defaultHapchungEvents: [HapchungEvent] = [
        HapchungEvent(
            branch1: HapchungBranch(hanja: "申", hangul: "신금"),
            branch2: HapchungBranch(hanja: "巳", hangul: "사화"),
            kind: "육합",
            impact: .positive,
            score: 12,
            note: "일지 · 시지 → 배우자/파트너 관계 강화"
        ),
        HapchungEvent(
            branch1: HapchungBranch(hanja: "卯", hangul: "묘목"),
            branch2: HapchungBranch(hanja: "酉", hangul: "유금"),
            kind: "월지충",
            impact: .negative,
            score: -18,
            note: "직업궁 충돌 → 부서 이동/갈등 주의"
        )
    ]
}

// MARK: - Helpers

enum TodayDetailFormatting {
    /// 양수는 "+12", 음수는 U+2212 minus 기호로 "−18" 포맷.
    /// 0은 "+0".
    static func formattedScore(_ value: Int) -> String {
        if value < 0 {
            return "−\(abs(value))"
        }
        return "+\(value)"
    }
}
