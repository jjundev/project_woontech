import Foundation

/// 사주 학습 경로의 주간 진행 요약.
struct WeeklyProgress: Hashable {
    /// 이번 주 완료한 강의 수.
    let completed: Int
    /// 이번 주 목표 강의 수.
    let goal: Int
    /// 연속 학습 일수(예: 3일).
    let streakDays: Int
}

/// 사주 학습 경로의 한 코스(입문/오행/십성/대운 등).
struct SajuCourse: Hashable {
    enum Status: String, Hashable, CaseIterable {
        case completed
        case current
        case unfinished
        case locked
    }

    let id: String
    let title: String
    let lessonCount: Int
    /// 0.0 ~ 1.0 사이의 진행률.
    let progress: Double
    let status: Status
}

/// Block B 오늘의 한 가지 카드에 바인딩되는 추천 레슨.
struct FeaturedLesson: Hashable {
    let id: String            // e.g. "L-TEN-001"
    let title: String         // e.g. "십성이란 무엇인가?"
    let durationLabel: String // e.g. "3분"
    let levelLabel: String    // e.g. "초급"
}

/// Block C 학습 경로 그리드의 한 코스 슬롯.
struct CoursePath: Hashable {
    let name: String         // e.g. "입문"
    let lessonCount: Int     // e.g. 7
    let averageMinutes: Int? // 옵셔널
    let progress: Double     // 0.0 ~ 1.0, 클램프 필요
}

protocol SajuLearningPathProviding {
    var weeklyProgress: WeeklyProgress { get }
    var courses: [SajuCourse] { get }
    // WF4-03 신규
    var streakDays: Int { get }
    var featuredLesson: FeaturedLesson? { get }
    var coursePaths: [CoursePath] { get }
    var glossaryTermCount: Int { get }
}

/// Default 구현 — 기존 채택자들이 streakDays / coursePaths를 명시적으로
/// 구현하지 않아도 컴파일되도록 weeklyProgress / courses에서 위임한다.
extension SajuLearningPathProviding {
    var streakDays: Int { weeklyProgress.streakDays }
    var coursePaths: [CoursePath] {
        courses.map {
            CoursePath(
                name: $0.title,
                lessonCount: $0.lessonCount,
                averageMinutes: nil,
                progress: $0.progress
            )
        }
    }
}

struct MockSajuLearningPathProvider: SajuLearningPathProviding {
    var weeklyProgress: WeeklyProgress
    var courses: [SajuCourse]
    var featuredLesson: FeaturedLesson?
    var glossaryTermCount: Int

    init(
        weeklyProgress: WeeklyProgress = WeeklyProgress(completed: 3, goal: 5, streakDays: 3),
        courses: [SajuCourse] = MockSajuLearningPathProvider.defaultCourses,
        featuredLesson: FeaturedLesson? = FeaturedLesson(
            id: "L-TEN-001",
            title: "십성이란 무엇인가?",
            durationLabel: "3분",
            levelLabel: "초급"
        ),
        glossaryTermCount: Int = 120
    ) {
        self.weeklyProgress = weeklyProgress
        self.courses = courses
        self.featuredLesson = featuredLesson
        self.glossaryTermCount = glossaryTermCount
    }

    /// 와이어프레임(screens-06-saju-tab.jsx)의 4코스 — 입문 / 오행 / 십성 / 대운.
    static let defaultCourses: [SajuCourse] = [
        SajuCourse(id: "intro",    title: "입문", lessonCount: 7, progress: 1.0, status: .completed),
        SajuCourse(id: "elements", title: "오행", lessonCount: 5, progress: 0.6, status: .current),
        SajuCourse(id: "tenGods",  title: "십성", lessonCount: 8, progress: 0.3, status: .unfinished),
        SajuCourse(id: "daewoon",  title: "대운", lessonCount: 6, progress: 0.0, status: .locked),
    ]
}
