import Foundation

// MARK: - WF4-07 모델 타입

/// 퀴즈 보기 하나.
struct Choice: Hashable {
    let symbol: String
}

/// 인라인 퀴즈 (4지선다, 고정).
struct Quiz: Hashable {
    let label: String
    let question: String
    let choices: [Choice]
    let correctIndex: Int
}

/// 레슨 상세 화면에 바인딩되는 전체 데이터.
struct Lesson: Hashable {
    let id: String
    let number: Int
    let title: String
    let currentIndex: Int
    let totalCount: Int
    let sectionLabel: String
    let headline: String
    let conceptBox: String
    let diagramPlaceholderLabel: String
    let quiz: Quiz
    let nextLessonId: String?
    /// true이면 알 수 없는 id에 대한 fallback lesson이다.
    /// 뷰에서 퀴즈 카드를 숨기고 CTA를 비활성화하는 데 사용.
    let isFallback: Bool
}

// MARK: - 프로토콜

protocol SajuLessonProviding {
    func lesson(id: String) -> Lesson
}

// MARK: - Mock

struct MockSajuLessonProvider: SajuLessonProviding {

    // MARK: Default lesson (WF4-07 기본값)

    static let defaultLesson = Lesson(
        id: "L-OH-003",
        number: 3,
        title: "오행의 의미",
        currentIndex: 3,
        totalCount: 7,
        sectionLabel: "기본 개념",
        headline: "오행이란?",
        conceptBox: "오행은 木·火·土·金·水의 다섯 요소로, 세상 모든 것을 다섯 기운의 흐름으로 설명하는 명리학의 기본 틀입니다.",
        diagramPlaceholderLabel: "상생·상극 다이어그램",
        quiz: Quiz(
            label: "간단 체크",
            question: "水를 생(生)하는 오행은?",
            choices: [Choice(symbol: "木"), Choice(symbol: "火"), Choice(symbol: "金"), Choice(symbol: "土")],
            correctIndex: 2
        ),
        nextLessonId: "L-OH-004",
        isFallback: false
    )

    // MARK: "L-OH-LAST" — 마지막 레슨 (nextLessonId nil)

    static let lastLesson = Lesson(
        id: "L-OH-LAST",
        number: 7,
        title: "오행 마무리",
        currentIndex: 7,
        totalCount: 7,
        sectionLabel: "기본 개념",
        headline: "오행 마무리",
        conceptBox: "오행의 모든 개념을 다시 한번 정리합니다.",
        diagramPlaceholderLabel: "오행 요약 다이어그램",
        quiz: Quiz(
            label: "최종 체크",
            question: "火를 생(生)하는 오행은?",
            choices: [Choice(symbol: "水"), Choice(symbol: "木"), Choice(symbol: "土"), Choice(symbol: "金")],
            correctIndex: 1
        ),
        nextLessonId: nil,
        isFallback: false
    )

    // MARK: Fallback lesson

    static let fallbackLesson = Lesson(
        id: "__fallback__",
        number: 0,
        title: "준비중",
        currentIndex: 0,
        totalCount: 1,
        sectionLabel: "",
        headline: "준비중",
        conceptBox: "",
        diagramPlaceholderLabel: "",
        quiz: Quiz(
            label: "",
            question: "",
            choices: [Choice(symbol: ""), Choice(symbol: ""), Choice(symbol: ""), Choice(symbol: "")],
            correctIndex: 0
        ),
        nextLessonId: nil,
        isFallback: true
    )

    // MARK: - SajuLessonProviding

    func lesson(id: String) -> Lesson {
        switch id {
        case "L-OH-003":
            return MockSajuLessonProvider.defaultLesson
        case "L-OH-LAST":
            return MockSajuLessonProvider.lastLesson
        default:
            return MockSajuLessonProvider.fallbackLesson
        }
    }
}

/// UI 테스트 전용 — `-sajuLessonNoNextId` launch arg 시 사용.
/// 모든 id에 대해 nextLessonId=nil인 레슨을 반환한다 (TU-LS16/17).
struct NoNextLessonProvider: SajuLessonProviding {
    func lesson(id: String) -> Lesson {
        MockSajuLessonProvider.lastLesson
    }
}
