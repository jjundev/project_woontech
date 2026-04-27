import Foundation

/// 십성 분석 상세(WF4-05)의 데이터 시그니처.
///
/// 본 슬라이스(WF4-01)에서는 시그니처만 선언하고 실제 모델 확장은 WF4-05에서.
protocol SajuTenGodsDetailProviding {
    /// 십성 요약 한 줄(예: "정재가 중심인 사주").
    var summaryLine: String { get }
}

struct MockSajuTenGodsDetailProvider: SajuTenGodsDetailProviding {
    var summaryLine: String

    init(summaryLine: String = "정재가 중심인 사주") {
        self.summaryLine = summaryLine
    }
}
