import Foundation

// MARK: - WF4-06 신규 모델 타입

/// 카테고리 필터 pill 아이템.
struct LearnCategory: Hashable, Identifiable {
    let id: String
    let label: String
}

/// 레슨 상태 (듀오링고식 4-상태).
enum LessonStatus: String, Hashable, CaseIterable {
    case completed
    case current
    case pending
    case locked
}

/// 코스 내 개별 레슨 행.
struct LessonRow: Hashable, Identifiable {
    let id: String
    let number: Int
    let title: String
    let durationLabel: String
    let status: LessonStatus
}

/// 한 코스(입문 등)의 메타 + 레슨 목록.
struct CourseSection: Hashable {
    let name: String
    let lessonCount: Int
    let averageMinutes: Int
    let lessons: [LessonRow]
}

/// 추천 아티클 아이템.
struct Article: Hashable, Identifiable {
    let id: String
    let title: String
    let metaLabel: String
}

// MARK: - WeeklyProgress

/// 사주 학습 경로의 주간 진행 요약.
struct WeeklyProgress: Hashable {
    /// 이번 주 완료한 강의 수.
    let completed: Int
    /// 이번 주 목표 강의 수.
    let goal: Int
    /// 연속 학습 일수(예: 3일).
    let streakDays: Int

    /// 진행률 (0.0 ~ 1.0). goal이 0이면 0.0 반환.
    var ratio: Double {
        goal > 0 ? Double(completed) / Double(goal) : 0.0
    }
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
    // WF4-06 신규
    var learnCategories: [LearnCategory] { get }
    var introductoryCourse: CourseSection { get }
    var recommendedArticles: [Article] { get }
}

/// Default 구현 — 기존 채택자들이 streakDays / coursePaths를 명시적으로
/// 구현하지 않아도 컴파일되도록 weeklyProgress / courses에서 위임한다.
/// WF4-06 신규 3개 요건도 default 구현을 제공해 기존 채택자 컴파일 보호.
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

    var learnCategories: [LearnCategory] {
        [
            LearnCategory(id: "all",       label: "전체"),
            LearnCategory(id: "intro",     label: "입문"),
            LearnCategory(id: "elements",  label: "오행"),
            LearnCategory(id: "tenGods",   label: "십성"),
            LearnCategory(id: "daewoon",   label: "대운"),
            LearnCategory(id: "hapchung",  label: "합충"),
        ]
    }

    var introductoryCourse: CourseSection {
        CourseSection(
            name: "입문",
            lessonCount: 7,
            averageMinutes: 3,
            lessons: [
                LessonRow(id: "L1", number: 1, title: "사주란 무엇인가",   durationLabel: "3분", status: .completed),
                LessonRow(id: "L2", number: 2, title: "천간과 지지",       durationLabel: "4분", status: .completed),
                LessonRow(id: "L3", number: 3, title: "오행의 의미",       durationLabel: "3분", status: .completed),
                LessonRow(id: "L4", number: 4, title: "일간이 나를 나타낸다", durationLabel: "5분", status: .current),
                LessonRow(id: "L5", number: 5, title: "지장간이란",        durationLabel: "4분", status: .locked),
                LessonRow(id: "L6", number: 6, title: "절기와 월주",       durationLabel: "4분", status: .locked),
                LessonRow(id: "L7", number: 7, title: "내 사주를 읽는 법", durationLabel: "6분", status: .locked),
            ]
        )
    }

    var recommendedArticles: [Article] { [] }
}

struct MockSajuLearningPathProvider: SajuLearningPathProviding {
    var weeklyProgress: WeeklyProgress
    var courses: [SajuCourse]
    var featuredLesson: FeaturedLesson?
    var glossaryTermCount: Int
    // WF4-06 신규
    var learnCategories: [LearnCategory]
    var introductoryCourse: CourseSection
    var recommendedArticles: [Article]

    init(
        weeklyProgress: WeeklyProgress = WeeklyProgress(completed: 3, goal: 5, streakDays: 3),
        courses: [SajuCourse] = MockSajuLearningPathProvider.defaultCourses,
        featuredLesson: FeaturedLesson? = FeaturedLesson(
            id: "L-TEN-001",
            title: "십성이란 무엇인가?",
            durationLabel: "3분",
            levelLabel: "초급"
        ),
        glossaryTermCount: Int = 120,
        learnCategories: [LearnCategory] = MockSajuLearningPathProvider.defaultLearnCategories,
        introductoryCourse: CourseSection = MockSajuLearningPathProvider.defaultIntroductoryCourse,
        recommendedArticles: [Article] = MockSajuLearningPathProvider.defaultRecommendedArticles
    ) {
        self.weeklyProgress = weeklyProgress
        self.courses = courses
        self.featuredLesson = featuredLesson
        self.glossaryTermCount = glossaryTermCount
        self.learnCategories = learnCategories
        self.introductoryCourse = introductoryCourse
        self.recommendedArticles = recommendedArticles
    }

    /// 와이어프레임(screens-06-saju-tab.jsx)의 4코스 — 입문 / 오행 / 십성 / 대운.
    static let defaultCourses: [SajuCourse] = [
        SajuCourse(id: "intro",    title: "입문", lessonCount: 7, progress: 1.0, status: .completed),
        SajuCourse(id: "elements", title: "오행", lessonCount: 5, progress: 0.6, status: .current),
        SajuCourse(id: "tenGods",  title: "십성", lessonCount: 8, progress: 0.3, status: .unfinished),
        SajuCourse(id: "daewoon",  title: "대운", lessonCount: 6, progress: 0.0, status: .locked),
    ]

    /// WF4-06: 6개 카테고리 필터 pill.
    static let defaultLearnCategories: [LearnCategory] = [
        LearnCategory(id: "all",      label: "전체"),
        LearnCategory(id: "intro",    label: "입문"),
        LearnCategory(id: "elements", label: "오행"),
        LearnCategory(id: "tenGods",  label: "십성"),
        LearnCategory(id: "daewoon",  label: "대운"),
        LearnCategory(id: "hapchung", label: "합충"),
    ]

    /// WF4-06: 7강 입문 코스 기본값.
    static let defaultIntroductoryCourse: CourseSection = CourseSection(
        name: "입문",
        lessonCount: 7,
        averageMinutes: 3,
        lessons: [
            LessonRow(id: "L1", number: 1, title: "사주란 무엇인가",      durationLabel: "3분", status: .completed),
            LessonRow(id: "L2", number: 2, title: "천간과 지지",          durationLabel: "4분", status: .completed),
            LessonRow(id: "L3", number: 3, title: "오행의 의미",          durationLabel: "3분", status: .completed),
            LessonRow(id: "L4", number: 4, title: "일간이 나를 나타낸다", durationLabel: "5분", status: .current),
            LessonRow(id: "L5", number: 5, title: "지장간이란",           durationLabel: "4분", status: .locked),
            LessonRow(id: "L6", number: 6, title: "절기와 월주",          durationLabel: "4분", status: .locked),
            LessonRow(id: "L7", number: 7, title: "내 사주를 읽는 법",   durationLabel: "6분", status: .locked),
        ]
    )

    /// WF4-06: 추천 아티클 기본값 2건.
    static let defaultRecommendedArticles: [Article] = [
        Article(id: "A1", title: "내 사주 일간이 丙(병)이면 어떤 사람?", metaLabel: "읽기 · 4분"),
        Article(id: "A2", title: "水가 없는 사주, 투자에 미치는 영향",   metaLabel: "읽기 · 5분"),
    ]
}
