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

protocol SajuLearningPathProviding {
    var weeklyProgress: WeeklyProgress { get }
    var courses: [SajuCourse] { get }
}

struct MockSajuLearningPathProvider: SajuLearningPathProviding {
    var weeklyProgress: WeeklyProgress
    var courses: [SajuCourse]

    init(
        weeklyProgress: WeeklyProgress = WeeklyProgress(completed: 3, goal: 5, streakDays: 3),
        courses: [SajuCourse] = MockSajuLearningPathProvider.defaultCourses
    ) {
        self.weeklyProgress = weeklyProgress
        self.courses = courses
    }

    /// 와이어프레임(screens-06-saju-tab.jsx)의 4코스 — 입문 / 오행 / 십성 / 대운.
    static let defaultCourses: [SajuCourse] = [
        SajuCourse(id: "intro",    title: "입문", lessonCount: 7, progress: 1.0, status: .completed),
        SajuCourse(id: "elements", title: "오행", lessonCount: 5, progress: 0.6, status: .current),
        SajuCourse(id: "tenGods",  title: "십성", lessonCount: 8, progress: 0.3, status: .unfinished),
        SajuCourse(id: "daewoon",  title: "대운", lessonCount: 6, progress: 0.0, status: .locked),
    ]
}
