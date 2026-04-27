import Foundation

/// 4주(時/日/月/年) 한 기둥 모델.
///
/// `heavenlyStem`(천간)과 `earthlyBranch`(지지)는 한자 1자, `element`는
/// 색상 매핑용 오행 키("wood"/"fire"/"earth"/"metal"/"water").
struct Pillar: Hashable {
    enum Position: String, Hashable, CaseIterable {
        case hour
        case day
        case month
        case year
    }

    let position: Position
    let heavenlyStem: String
    let earthlyBranch: String
    let element: String
}

protocol UserSajuOriginProviding {
    /// 시·일·월·년 4기둥 (UI 정렬은 표시 단계에서 결정).
    var pillars: [Pillar] { get }

    /// 일간 한 줄 해석 — "일간 丙火 · 양의 불 — 따뜻함, 표현력, 리더십" 등.
    var dayMasterLine: String { get }
}

struct MockUserSajuOriginProvider: UserSajuOriginProviding {
    var pillars: [Pillar]
    var dayMasterLine: String

    init(
        pillars: [Pillar] = MockUserSajuOriginProvider.defaultPillars,
        dayMasterLine: String = "일간 丙火 · 양의 불 — 따뜻함, 표현력, 리더십"
    ) {
        self.pillars = pillars
        self.dayMasterLine = dayMasterLine
    }

    /// 와이어프레임 기본값 — 時庚申 / 日丙午 / 月辛卯 / 年庚午.
    static let defaultPillars: [Pillar] = [
        Pillar(position: .hour,  heavenlyStem: "庚", earthlyBranch: "申", element: "metal"),
        Pillar(position: .day,   heavenlyStem: "丙", earthlyBranch: "午", element: "fire"),
        Pillar(position: .month, heavenlyStem: "辛", earthlyBranch: "卯", element: "wood"),
        Pillar(position: .year,  heavenlyStem: "庚", earthlyBranch: "午", element: "fire"),
    ]
}
