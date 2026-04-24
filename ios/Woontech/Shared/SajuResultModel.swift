import Foundation

// MARK: - 사주 원국 미니 차트 Pillar

/// 4주(시·일·월·년) 한 기둥 = 천간(Stem) + 지지(Branch) + 오행(Element) 라벨.
struct SajuPillar: Codable, Equatable, Hashable {
    /// 천간 (예: "경").
    var stem: String
    /// 지지 (예: "자").
    var branch: String
    /// 오행(목·화·토·금·수) 라벨. 접근성 announcement용.
    var element: String
    /// 일간 강조 여부.
    var isDayPillar: Bool

    static let unknown = SajuPillar(stem: "", branch: "", element: "", isDayPillar: false)
}

// MARK: - 오행 막대

enum WuxingElement: String, Codable, CaseIterable, Equatable {
    case wood   // 목
    case fire   // 화
    case earth  // 토
    case metal  // 금
    case water  // 수

    var label: String {
        switch self {
        case .wood: return "목"
        case .fire: return "화"
        case .earth: return "토"
        case .metal: return "금"
        case .water: return "수"
        }
    }
}

struct WuxingBar: Codable, Equatable, Hashable {
    var element: WuxingElement
    /// 0.0 ~ 1.0.
    var value: Double
}

// MARK: - 결과 모델

struct SajuResultModel: Codable, Equatable {
    /// 유형명 (예: "단단한 수집가형").
    var typeName: String
    /// 일주/십성 요약 (예: "경금(庚金) 일주 · 정재 중심").
    var dayPillarSummary: String
    /// 한 줄 설명.
    var oneLiner: String

    /// 4주: 시·일·월·년 순서(표시 순서는 뷰에서 제어).
    var hourPillar: SajuPillar
    var dayPillar: SajuPillar
    var monthPillar: SajuPillar
    var yearPillar: SajuPillar

    /// 시주 미입력 여부 — FR-8.5 / AC-18.
    var hourUnknown: Bool

    /// 오행 막대 (5개).
    var wuxing: [WuxingBar]
    /// 오행 경고 문구 (예: "水 부재 · 火·金 과다 — 충동 판단 제어 필요").
    var wuxingWarning: String

    /// 강점(3개).
    var strengths: [String]
    /// 주의점(3개 · 빨간 불릿).
    var cautions: [String]
    /// 접근 참고(3개).
    var approaches: [String]

    /// 입력 정보 요약 문자열 (예: "1990.03.15 05:30 · 서울특별시 · 남").
    var inputSummary: String

    /// 결과 생성 시점의 정확도.
    var accuracy: AccuracyLevel
}
