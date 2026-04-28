import Foundation

// MARK: - Models

/// 오행 분포 상세 화면의 개별 원소 데이터 (WF4-04).
struct ElementDistribution: Equatable {
    /// 한자 기호 (예: "火").
    let symbol: String
    /// 한국어명 (예: "불").
    let koreanName: String
    /// 해당 원소 글자 수 (0~max).
    let count: Int
    /// 기준 최대치 (기본값 4).
    let max: Int
    /// 표시 메모 (예: "왕성", "부족 ⚠").
    let note: String
    /// 부족 여부. true이면 채움 색을 약한 톤으로 시각 구분.
    let isDeficient: Bool
}

/// 부족 원소 보완 가이드 데이터 (WF4-04).
struct ElementGuidance: Equatable {
    /// 부족 원소 한자 (예: "水"). 카드 헤더에 "부족한 {targetSymbol}를 보완하려면" 형태로 표시.
    let targetSymbol: String
    /// 방향 가이드 (예: "북쪽이 유리").
    let direction: String
    /// 색상 가이드 (예: "검정·파랑 계열").
    let color: String
    /// 시간 가이드 (예: "저녁 23시 ~ 새벽 1시").
    let time: String
    /// 행동 가이드 (예: "계획·독서·수영").
    let action: String
}

// MARK: - Protocol

/// 오행 분포 상세(WF4-04)의 데이터 시그니처.
///
/// `SajuCategoriesProviding`과는 완전히 별개의 프로토콜로,
/// 두 프로토콜 사이에 타입 · 인스턴스 어느 쪽도 공유하지 않는다(AC#12).
protocol SajuElementsDetailProviding {
    /// 요약 한줄 (bold 표시용). 예: "火가 많고 水가 전혀 없는 사주".
    var summaryHeadline: String { get }
    /// 요약 보조 본문 (muted 표시용).
    var summaryBody: String { get }
    /// 5행 분포 배열. 길이는 반드시 5이고 [火, 木, 土, 金, 水] 순서로 제공되어야 한다(AC#4).
    var elements: [ElementDistribution] { get }
    /// 부족 원소 보완 가이드. nil이면 가이드 카드 전체 숨김(AC#9).
    var guidance: ElementGuidance? { get }
}

// MARK: - Mock

/// WF4-04 개발·테스트 용 기본 provider. 와이어프레임 텍스트 및 수치를 기본값으로 가진다.
struct MockSajuElementsDetailProvider: SajuElementsDetailProviding {
    var summaryHeadline: String
    var summaryBody: String
    var elements: [ElementDistribution]
    var guidance: ElementGuidance?

    init(
        summaryHeadline: String = "火가 많고 水가 전혀 없는 사주",
        summaryBody: String = "열정·추진력이 강하나 침착함·저축의 기운이 부족합니다.",
        elements: [ElementDistribution] = MockSajuElementsDetailProvider.defaultElements,
        guidance: ElementGuidance? = MockSajuElementsDetailProvider.defaultGuidance
    ) {
        self.summaryHeadline = summaryHeadline
        self.summaryBody = summaryBody
        self.elements = elements
        self.guidance = guidance
    }

    /// 와이어프레임 기본 5행 분포 (火 3/4, 木 1/4, 土 2/4, 金 2/4, 水 0/4).
    static let defaultElements: [ElementDistribution] = [
        ElementDistribution(symbol: "火", koreanName: "불",  count: 3, max: 4, note: "왕성",   isDeficient: false),
        ElementDistribution(symbol: "木", koreanName: "나무", count: 1, max: 4, note: "보통",   isDeficient: false),
        ElementDistribution(symbol: "土", koreanName: "흙",  count: 2, max: 4, note: "보통",   isDeficient: false),
        ElementDistribution(symbol: "金", koreanName: "쇠",  count: 2, max: 4, note: "보통",   isDeficient: false),
        ElementDistribution(symbol: "水", koreanName: "물",  count: 0, max: 4, note: "부족 ⚠", isDeficient: true),
    ]

    /// 와이어프레임 기본 보완 가이드 (부족 원소: 水).
    static let defaultGuidance = ElementGuidance(
        targetSymbol: "水",
        direction: "북쪽이 유리",
        color: "검정·파랑 계열",
        time: "저녁 23시 ~ 새벽 1시",
        action: "계획·독서·수영"
    )
}
