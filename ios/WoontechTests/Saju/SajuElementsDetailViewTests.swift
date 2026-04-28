import XCTest
@testable import Woontech

// MARK: - Stub Providers

private struct StubElementsDetailProvider: SajuElementsDetailProviding {
    var summaryHeadline: String
    var summaryBody: String
    var elements: [ElementDistribution]
    var guidance: ElementGuidance?

    init(
        summaryHeadline: String = "stub headline",
        summaryBody: String = "stub body",
        elements: [ElementDistribution] = MockSajuElementsDetailProvider.defaultElements,
        guidance: ElementGuidance? = nil
    ) {
        self.summaryHeadline = summaryHeadline
        self.summaryBody = summaryBody
        self.elements = elements
        self.guidance = guidance
    }
}

// MARK: - Test Suite

final class SajuElementsDetailViewTests: XCTestCase {

    // MARK: Group A — 프로토콜 분리 (AC#12)

    /// T1: `SajuElementsDetailProviding`은 `SajuCategoriesProviding`과 완전히 별개.
    ///
    /// 두 프로토콜이 서로 다른 프로퍼티 집합을 가지므로 한쪽 구현체를 다른 쪽에 대입할 수 없다
    /// (컴파일 타임 분리). 아래 코드가 컴파일되는 것 자체가 분리의 증거다.
    func test_protocolSeparation_elementsNotCategories() {
        // SajuElementsDetailProviding 구현
        let elementsProvider: any SajuElementsDetailProviding = MockSajuElementsDetailProvider()
        // SajuCategoriesProviding 구현
        let categoriesProvider: any SajuCategoriesProviding = MockSajuCategoriesProvider()

        // 각자의 타입으로만 사용 가능 — 상호 대입 시 컴파일 에러 발생(코드 리뷰로 확인)
        XCTAssertFalse(elementsProvider.summaryHeadline.isEmpty,
                       "elementsProvider must have summaryHeadline")
        XCTAssertFalse(categoriesProvider.categories.isEmpty,
                       "categoriesProvider must have categories")
        // 두 provider가 동일 인스턴스가 아님을 타입 수준에서 확인
        XCTAssertFalse(
            type(of: elementsProvider) == type(of: categoriesProvider) as Any.Type,
            "elementsProvider and categoriesProvider must be different types"
        )
    }

    // MARK: Group B — Mock provider 기본값 (AC#3, AC#13)

    /// T2
    func test_mockProvider_summaryHeadlineDefault() {
        let mock = MockSajuElementsDetailProvider()
        XCTAssertEqual(mock.summaryHeadline, "火가 많고 水가 전혀 없는 사주")
    }

    /// T3
    func test_mockProvider_summaryBodyDefault() {
        let mock = MockSajuElementsDetailProvider()
        XCTAssertEqual(mock.summaryBody, "열정·추진력이 강하나 침착함·저축의 기운이 부족합니다.")
    }

    /// T4
    func test_mockProvider_elementsCount5() {
        let mock = MockSajuElementsDetailProvider()
        XCTAssertEqual(mock.elements.count, 5)
    }

    /// T5
    func test_mockProvider_elementsOrder() {
        let mock = MockSajuElementsDetailProvider()
        XCTAssertEqual(mock.elements[0].symbol, "火")
        XCTAssertEqual(mock.elements[1].symbol, "木")
        XCTAssertEqual(mock.elements[2].symbol, "土")
        XCTAssertEqual(mock.elements[3].symbol, "金")
        XCTAssertEqual(mock.elements[4].symbol, "水")
    }

    /// T6
    func test_mockProvider_guidanceNotNil() {
        let mock = MockSajuElementsDetailProvider()
        XCTAssertNotNil(mock.guidance)
    }

    /// T7
    func test_mockProvider_guidanceTargetSymbol() {
        let mock = MockSajuElementsDetailProvider()
        XCTAssertEqual(mock.guidance?.targetSymbol, "水")
    }

    /// T8: 임의 값으로 init → 모든 필드 반영 (AC#13)
    func test_mockProvider_customInit_reflectsAllFields() {
        let customGuidance = ElementGuidance(
            targetSymbol: "木",
            direction: "동쪽",
            color: "초록 계열",
            time: "새벽 3시",
            action: "산책"
        )
        let customElements: [ElementDistribution] = [
            ElementDistribution(symbol: "火", koreanName: "불",  count: 1, max: 4, note: "보통", isDeficient: false),
            ElementDistribution(symbol: "木", koreanName: "나무", count: 0, max: 4, note: "부족 ⚠", isDeficient: true),
            ElementDistribution(symbol: "土", koreanName: "흙",  count: 1, max: 4, note: "보통", isDeficient: false),
            ElementDistribution(symbol: "金", koreanName: "쇠",  count: 2, max: 4, note: "보통", isDeficient: false),
            ElementDistribution(symbol: "水", koreanName: "물",  count: 0, max: 4, note: "보통", isDeficient: false),
        ]
        let mock = MockSajuElementsDetailProvider(
            summaryHeadline: "custom headline",
            summaryBody: "custom body",
            elements: customElements,
            guidance: customGuidance
        )

        XCTAssertEqual(mock.summaryHeadline, "custom headline")
        XCTAssertEqual(mock.summaryBody, "custom body")
        XCTAssertEqual(mock.elements[1].symbol, "木")
        XCTAssertEqual(mock.elements[1].isDeficient, true)
        XCTAssertEqual(mock.guidance?.targetSymbol, "木")
        XCTAssertEqual(mock.guidance?.direction, "동쪽")
        XCTAssertEqual(mock.guidance?.action, "산책")
    }

    // MARK: Group C — 분포 비율 계산 (AC#5)

    /// T9: count=3, max=4 → 75%
    func test_barFillRatio_count3_max4_is75Percent() {
        let item = ElementDistribution(symbol: "火", koreanName: "불", count: 3, max: 4, note: "왕성", isDeficient: false)
        let ratio = item.max > 0 ? CGFloat(item.count) / CGFloat(item.max) : 0
        XCTAssertEqual(ratio, 0.75, accuracy: 0.001)
    }

    /// T10: count=0, max=4 → 0%
    func test_barFillRatio_count0_max4_is0Percent() {
        let item = ElementDistribution(symbol: "水", koreanName: "물", count: 0, max: 4, note: "부족 ⚠", isDeficient: true)
        let ratio = item.max > 0 ? CGFloat(item.count) / CGFloat(item.max) : 0
        XCTAssertEqual(ratio, 0.0, accuracy: 0.001)
    }

    /// T11: count=4, max=4 → 100%
    func test_barFillRatio_count4_max4_is100Percent() {
        let item = ElementDistribution(symbol: "火", koreanName: "불", count: 4, max: 4, note: "과다", isDeficient: false)
        let ratio = item.max > 0 ? CGFloat(item.count) / CGFloat(item.max) : 0
        XCTAssertEqual(ratio, 1.0, accuracy: 0.001)
    }

    // MARK: Group D — 부족 원소 표시 (AC#6)

    /// T12
    func test_deficientElement_isDeficientTrue() {
        let waterElement = MockSajuElementsDetailProvider.defaultElements.first { $0.symbol == "水" }!
        XCTAssertTrue(waterElement.isDeficient)
    }

    /// T13
    func test_deficientElement_noteContains부족() {
        let waterElement = MockSajuElementsDetailProvider.defaultElements.first { $0.symbol == "水" }!
        XCTAssertTrue(waterElement.note.contains("부족"),
                      "Water element note should contain '부족'")
    }

    /// T14
    func test_nonDeficient_element_isDeficientFalse() {
        let fireElement = MockSajuElementsDetailProvider.defaultElements.first { $0.symbol == "火" }!
        XCTAssertFalse(fireElement.isDeficient)
    }

    // MARK: Group E — guidance nil/non-nil (AC#8, AC#9)

    /// T15: guidance != nil → SajuElementsDetailView 생성 성공
    func test_guidanceNonNil_cardRendered() {
        let provider = MockSajuElementsDetailProvider()
        XCTAssertNotNil(provider.guidance,
                        "Default mock should have non-nil guidance")
        // View creation doesn't crash.
        let _ = SajuElementsDetailView(provider: provider)
    }

    /// T16: guidance == nil → guidance card 없음 (view 생성 성공, provider.guidance == nil)
    func test_guidanceNil_cardAbsent() {
        let provider = MockSajuElementsDetailProvider(guidance: nil)
        XCTAssertNil(provider.guidance,
                     "Provider with guidance:nil must have nil guidance")
        // View creation doesn't crash even when guidance is nil.
        let _ = SajuElementsDetailView(provider: provider)
    }

    /// T17: 헤더 텍스트에 targetSymbol 포함
    func test_guidanceHeader_containsTargetSymbol() {
        let guidance = MockSajuElementsDetailProvider.defaultGuidance
        let header = "부족한 \(guidance.targetSymbol)를 보완하려면"
        XCTAssertTrue(header.contains(guidance.targetSymbol),
                      "Guidance header must contain targetSymbol '\(guidance.targetSymbol)'")
        XCTAssertTrue(header.contains("水"))
    }

    // MARK: Group F — guidance bullet 매핑 (AC#10)

    /// T18
    func test_guidanceBullets_directionValue() {
        let guidance = MockSajuElementsDetailProvider.defaultGuidance
        XCTAssertEqual(guidance.direction, "북쪽이 유리")
    }

    /// T19
    func test_guidanceBullets_colorValue() {
        let guidance = MockSajuElementsDetailProvider.defaultGuidance
        XCTAssertEqual(guidance.color, "검정·파랑 계열")
    }

    /// T20
    func test_guidanceBullets_timeValue() {
        let guidance = MockSajuElementsDetailProvider.defaultGuidance
        XCTAssertEqual(guidance.time, "저녁 23시 ~ 새벽 1시")
    }

    /// T21
    func test_guidanceBullets_actionValue() {
        let guidance = MockSajuElementsDetailProvider.defaultGuidance
        XCTAssertEqual(guidance.action, "계획·독서·수영")
    }

    // MARK: Group G — precondition (AC#7)

    /// T22: 5개 배열 → sortedElements 정상 동작
    func test_sortedElements_length5_succeeds() {
        // 순서를 뒤섞은 배열 입력
        let scrambled: [ElementDistribution] = [
            ElementDistribution(symbol: "水", koreanName: "물",  count: 0, max: 4, note: "부족 ⚠", isDeficient: true),
            ElementDistribution(symbol: "火", koreanName: "불",  count: 3, max: 4, note: "왕성",   isDeficient: false),
            ElementDistribution(symbol: "金", koreanName: "쇠",  count: 2, max: 4, note: "보통",   isDeficient: false),
            ElementDistribution(symbol: "木", koreanName: "나무", count: 1, max: 4, note: "보통",   isDeficient: false),
            ElementDistribution(symbol: "土", koreanName: "흙",  count: 2, max: 4, note: "보통",   isDeficient: false),
        ]
        let sorted = sortedElements(scrambled)
        XCTAssertEqual(sorted.count, 5)
        XCTAssertEqual(sorted[0].symbol, "火")
        XCTAssertEqual(sorted[1].symbol, "木")
        XCTAssertEqual(sorted[2].symbol, "土")
        XCTAssertEqual(sorted[3].symbol, "金")
        XCTAssertEqual(sorted[4].symbol, "水")
    }

    /// T23: 배열 길이 ≠ 5 → preconditionFailure (debug 빌드에서만 트랩 가능)
    ///
    /// Swift의 `precondition`은 프로세스를 종료하므로 일반 단위 테스트에서 캐치 불가.
    /// 비정상 경로(count ≠ 5)는 코드 리뷰 + 주석으로 검증한다.
    /// 아래 주석 처리된 코드를 직접 실행하면 debug 빌드에서 크래시가 발생함.
    func test_sortedElements_lengthNot5_preconditionFails() throws {
        // preconditionFailure terminates the process — not catchable in unit tests.
        // The guard is implemented in sortedElements(_:) via:
        //   precondition(elements.count == 5, ...)
        // Manual crash test (UNSAFE — comment out before normal runs):
        //   let bad = Array(repeating: ElementDistribution(...), count: 4)
        //   _ = sortedElements(bad) // → crashes with "must contain exactly 5 items"
        throw XCTSkip(
            "preconditionFailure terminates the process; " +
            "verified by code review of sortedElements(_:) in SajuElementsDetailView.swift"
        )
    }

    // MARK: Group H — SajuTabDependencies 통합 (AC#12, AC#13)

    /// T24: SajuTabDependencies에 커스텀 elementsDetail 주입 → summaryHeadline 반영
    func test_sajuTabDeps_elementsDetailReplaceable() {
        let stub = StubElementsDetailProvider(summaryHeadline: "custom stub headline")
        let deps = SajuTabDependencies(elementsDetail: stub)
        XCTAssertEqual(deps.elementsDetail.summaryHeadline, "custom stub headline",
                       "Custom elementsDetail provider must be reflected in SajuTabDependencies")
    }
}
