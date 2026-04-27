import Foundation

/// 오행 분포 상세(WF4-04)의 데이터 시그니처.
///
/// 본 슬라이스(WF4-01)에서는 시그니처만 선언하고 실제 모델 확장은 WF4-04에서.
protocol SajuElementsDetailProviding {
    /// 오행 요약 한 줄(예: "火가 많고 水가 전혀 없는 사주").
    var summaryLine: String { get }
}

struct MockSajuElementsDetailProvider: SajuElementsDetailProviding {
    var summaryLine: String

    init(summaryLine: String = "火가 많고 水가 전혀 없는 사주") {
        self.summaryLine = summaryLine
    }
}
