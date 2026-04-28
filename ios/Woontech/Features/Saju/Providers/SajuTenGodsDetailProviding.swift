import Foundation

// MARK: - Data Models

/// 5그룹 분포 중 한 그룹(비겁/식상/재성/관성/인성).
///
/// - Precondition: `items.count == 2`, `counts.count == 2`.
struct TenGodGroup: Equatable {
    /// 그룹 한국어명 (예: "비겁", "식상", "재성", "관성", "인성").
    let name: String
    /// 한자 표기 (예: "比劫", "食傷").
    let han: String
    /// 의미 설명 (예: "주체성·동료").
    let meaning: String
    /// 해당 그룹에 속하는 십성 이름 2개 — 길이 정확히 2.
    let items: [String]
    /// `items`와 1:1 대응하는 등장 횟수 — 길이 정확히 2.
    let counts: [Int]
    /// 총점 (0~8).
    let total: Int
    /// 핵심 그룹 여부.
    let isCore: Bool
    /// 부재 여부.
    let isAbsent: Bool
}

/// 핵심 십성 Top-3 중 하나.
struct CoreTenGod: Equatable {
    /// 한국어명 (예: "정재").
    let name: String
    /// 한자 (예: "正財").
    let han: String
    /// 등장 횟수.
    let count: Int
    /// 의미 설명.
    let meaning: String
    /// 투자 함의 (💹 박스 텍스트).
    let investImplication: String
}

/// 부재 십성 경고 카드 데이터.
struct AbsentWarning: Equatable {
    /// 경고 카드 제목 (예: "식상(식신·상관) 부재").
    let groupTitle: String
    /// 해당 십성 목록 (보관용; 현재 미표출).
    let items: String
    /// 경고 본문 텍스트.
    let copy: String
}

/// 학습 유도 카드 데이터.
struct LearnEntry: Equatable {
    /// 레슨 제목.
    let title: String
    /// 소요 시간 레이블 (예: "3분").
    let durationLabel: String
    /// 난이도 레이블 (예: "초급").
    let levelLabel: String
    /// 레슨 식별자 (예: "L-TEN-001").
    let lessonId: String
}

// MARK: - Protocol

/// 십성 분석 상세 화면(WF4-05)의 데이터 공급 프로토콜.
///
/// `SajuCategoriesProviding` 및 `SajuElementsDetailProviding`과 완전히 독립된 타입 계층을 갖는다.
protocol SajuTenGodsDetailProviding {
    /// 십성 요약 헤드라인 (예: "정재가 중심인 사주").
    var summaryHeadline: String { get }
    /// 요약 본문 (예: "꼼꼼하고 안정을 추구하는 기질…").
    var summaryBody: String { get }
    /// 5그룹 분포 배열 — 길이 정확히 5 (precondition).
    var groups: [TenGodGroup] { get }
    /// 핵심 십성 Top-3 — 길이 정확히 3 (precondition).
    var topThree: [CoreTenGod] { get }
    /// 부재 십성 경고 데이터. nil이면 경고 카드 전체 숨김.
    var absentWarning: AbsentWarning? { get }
    /// 학습 유도 카드 데이터. nil이면 카드 전체 숨김.
    var learnEntry: LearnEntry? { get }
}

// MARK: - Mock

/// WF4-05 UI 테스트·Preview·기본값에 사용하는 mock provider.
///
/// `MockSajuTenGodsDetailProvider(absentWarning: nil)` 또는
/// `MockSajuTenGodsDetailProvider(learnEntry: nil)` 로
/// 각각의 카드 숨김 시나리오를 테스트할 수 있다.
struct MockSajuTenGodsDetailProvider: SajuTenGodsDetailProviding {
    var summaryHeadline: String
    var summaryBody: String
    var groups: [TenGodGroup]
    var topThree: [CoreTenGod]
    var absentWarning: AbsentWarning?
    var learnEntry: LearnEntry?

    init(
        summaryHeadline: String = "정재가 중심인 사주",
        summaryBody: String = "꼼꼼하고 안정을 추구하는 기질로 투자 시 검증된 패턴을 선호합니다.",
        groups: [TenGodGroup] = MockSajuTenGodsDetailProvider.defaultGroups,
        topThree: [CoreTenGod] = MockSajuTenGodsDetailProvider.defaultTopThree,
        absentWarning: AbsentWarning? = MockSajuTenGodsDetailProvider.defaultAbsentWarning,
        learnEntry: LearnEntry? = MockSajuTenGodsDetailProvider.defaultLearnEntry
    ) {
        self.summaryHeadline = summaryHeadline
        self.summaryBody = summaryBody
        self.groups = groups
        self.topThree = topThree
        self.absentWarning = absentWarning
        self.learnEntry = learnEntry
    }

    // MARK: Default values

    static let defaultGroups: [TenGodGroup] = [
        TenGodGroup(
            name: "비겁", han: "比劫", meaning: "주체성·동료",
            items: ["비견", "겁재"], counts: [1, 0], total: 1,
            isCore: false, isAbsent: false
        ),
        TenGodGroup(
            name: "식상", han: "食傷", meaning: "표현·생산",
            items: ["식신", "상관"], counts: [0, 0], total: 0,
            isCore: false, isAbsent: true
        ),
        TenGodGroup(
            name: "재성", han: "財星", meaning: "재물·실리",
            items: ["편재", "정재"], counts: [0, 2], total: 2,
            isCore: true, isAbsent: false
        ),
        TenGodGroup(
            name: "관성", han: "官星", meaning: "명예·규율",
            items: ["편관", "정관"], counts: [0, 1], total: 1,
            isCore: false, isAbsent: false
        ),
        TenGodGroup(
            name: "인성", han: "印星", meaning: "학문·수용성",
            items: ["편인", "정인"], counts: [0, 1], total: 1,
            isCore: false, isAbsent: false
        ),
    ]

    static let defaultTopThree: [CoreTenGod] = [
        CoreTenGod(
            name: "정재", han: "正財", count: 2,
            meaning: "안정 수입·꼼꼼한 관리",
            investImplication: "장기 보유·분산 선호"
        ),
        CoreTenGod(
            name: "비견", han: "比肩", count: 1,
            meaning: "독립심·자기 원칙",
            investImplication: "독자적 판단, 군중 추종 회피"
        ),
        CoreTenGod(
            name: "정인", han: "正印", count: 1,
            meaning: "학습력·신중함",
            investImplication: "데이터·근거 기반 매매 선호"
        ),
    ]

    static let defaultAbsentWarning = AbsentWarning(
        groupTitle: "식상(식신·상관) 부재",
        items: "식신, 상관",
        copy: "창의적 직관 매매보다 검증된 패턴 매매가 내 성향에 맞아요"
    )

    static let defaultLearnEntry = LearnEntry(
        title: "십성이란 무엇인가요?",
        durationLabel: "3분",
        levelLabel: "초급",
        lessonId: "L-TEN-001"
    )
}
