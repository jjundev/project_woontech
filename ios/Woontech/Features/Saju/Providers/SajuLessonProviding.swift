import Foundation

/// 레슨 상세(WF4-07)의 데이터 시그니처.
///
/// 본 슬라이스(WF4-01)에서는 시그니처만 선언하고 실제 모델 확장은 WF4-07에서.
protocol SajuLessonProviding {
    /// 식별자에 대응하는 레슨 제목을 반환. nil이면 미존재.
    func lessonTitle(forId id: String) -> String?
}

struct MockSajuLessonProvider: SajuLessonProviding {
    var titlesById: [String: String]

    init(titlesById: [String: String] = MockSajuLessonProvider.defaultTitles) {
        self.titlesById = titlesById
    }

    func lessonTitle(forId id: String) -> String? {
        titlesById[id]
    }

    static let defaultTitles: [String: String] = [
        "L-001": "사주란 무엇인가",
        "L-002": "천간과 지지",
        "L-003": "오행의 의미",
    ]
}
