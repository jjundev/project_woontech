import XCTest
@testable import Woontech

final class TodayDetailViewTests: XCTestCase {

    // MARK: - U1: 4기둥 stem/branch 와이어프레임 값 (AC-3)

    func testMockProviderDefaults_sajuChartPillars() {
        let provider = MockTodayDetailProvider()
        let chart = provider.sajuChart

        XCTAssertEqual(chart.yearPillar.stem, "庚")
        XCTAssertEqual(chart.yearPillar.branch, "午")
        XCTAssertEqual(chart.monthPillar.stem, "己")
        XCTAssertEqual(chart.monthPillar.branch, "卯")
        XCTAssertEqual(chart.dayPillar.stem, "庚")
        XCTAssertEqual(chart.dayPillar.branch, "申")
        XCTAssertTrue(chart.dayPillar.isDayPillar)
        XCTAssertEqual(chart.hourPillar.stem, "丁")
        XCTAssertEqual(chart.hourPillar.branch, "巳")
        XCTAssertFalse(chart.hourUnknown)
    }

    // MARK: - U2: 오행 카운트 (AC-4)

    func testMockProviderDefaults_elementCounts() {
        let counts = MockTodayDetailProvider().sajuChart.elementCounts
        XCTAssertEqual(counts[.wood], 1)
        XCTAssertEqual(counts[.fire], 3)
        XCTAssertEqual(counts[.earth], 1)
        XCTAssertEqual(counts[.metal], 3)
        XCTAssertEqual(counts[.water], 0)
    }

    // MARK: - U3: weakElement (AC-5)

    func testMockProviderDefaults_weakElementIsWater() {
        XCTAssertEqual(MockTodayDetailProvider().weakElement, .water)
    }

    // MARK: - U4: 십성 (AC-6, AC-7)

    func testMockProviderDefaults_sipseong() {
        let info = MockTodayDetailProvider().sipseong
        XCTAssertEqual(info.name, "편관")
        XCTAssertEqual(info.hanja, "偏官")
        XCTAssertFalse(info.oneLiner.isEmpty)
        XCTAssertFalse(info.relation.isEmpty)
        XCTAssertFalse(info.examples.isEmpty)
    }

    // MARK: - U5: 합충 events (AC-9, AC-10)

    func testMockProviderDefaults_hapchungEvents() {
        let events = MockTodayDetailProvider().hapchungEvents
        XCTAssertEqual(events.count, 2)

        let first = events[0]
        XCTAssertEqual(first.branch1.hanja, "申")
        XCTAssertEqual(first.branch2.hanja, "巳")
        XCTAssertEqual(first.kind, "육합")
        XCTAssertEqual(first.impact, .positive)
        XCTAssertEqual(first.score, 12)

        let second = events[1]
        XCTAssertEqual(second.branch1.hanja, "卯")
        XCTAssertEqual(second.branch2.hanja, "酉")
        XCTAssertEqual(second.kind, "월지충")
        XCTAssertEqual(second.impact, .negative)
        XCTAssertEqual(second.score, -18)
    }

    // MARK: - U6: dailyMotto/Taboo nil 기본 (AC-11)

    func testMockProviderDefaults_dailyMottoTabooNil() {
        let provider = MockTodayDetailProvider()
        XCTAssertNil(provider.dailyMotto)
        XCTAssertNil(provider.dailyTaboo)
    }

    // MARK: - U7: 사용자 정의 mock 모든 필드 반영 (AC-13)

    func testCustomProvider_overridesAllFields() {
        let customChart = SajuChartData(
            yearPillar: SajuPillar(stem: "甲", branch: "子", stemElement: "목", branchElement: "수", isDayPillar: false),
            monthPillar: SajuPillar(stem: "乙", branch: "丑", stemElement: "목", branchElement: "토", isDayPillar: false),
            dayPillar: SajuPillar(stem: "丙", branch: "寅", stemElement: "화", branchElement: "목", isDayPillar: true),
            hourPillar: SajuPillar(stem: "丁", branch: "卯", stemElement: "화", branchElement: "목", isDayPillar: false),
            hourUnknown: false,
            dayMasterNature: "태양",
            investmentTags: "활력형",
            elementCounts: [.wood: 4, .fire: 2, .earth: 1, .metal: 0, .water: 1]
        )
        let customSipseong = SipseongInfo(
            name: "정인", hanja: "正印",
            oneLiner: "지원의 날",
            relation: "내 일간을 생하는 기운",
            examples: "학습 · 후원 · 회복"
        )
        let customEvents = [
            HapchungEvent(
                branch1: HapchungBranch(hanja: "子", hangul: "자수"),
                branch2: HapchungBranch(hanja: "丑", hangul: "축토"),
                kind: "육합",
                impact: .positive,
                score: 8,
                note: nil
            )
        ]

        let provider = MockTodayDetailProvider(
            sajuChart: customChart,
            weakElement: .metal,
            sipseong: customSipseong,
            hapchungEvents: customEvents,
            dailyMotto: "한마디",
            dailyTaboo: "금기"
        )

        XCTAssertEqual(provider.sajuChart.dayPillar.stem, "丙")
        XCTAssertEqual(provider.sajuChart.elementCounts[.wood], 4)
        XCTAssertEqual(provider.sajuChart.dayMasterNature, "태양")
        XCTAssertEqual(provider.weakElement, .metal)
        XCTAssertEqual(provider.sipseong.name, "정인")
        XCTAssertEqual(provider.sipseong.hanja, "正印")
        XCTAssertEqual(provider.hapchungEvents.count, 1)
        XCTAssertEqual(provider.hapchungEvents[0].score, 8)
        XCTAssertEqual(provider.dailyMotto, "한마디")
        XCTAssertEqual(provider.dailyTaboo, "금기")
    }

    // MARK: - U8: 모든 오행 ≥ 1 → weakElement nil (AC-5 부정)

    func testWeakElementNilWhenAllElementsPresent() {
        let chart = SajuChartData(
            yearPillar: SajuPillar(stem: "甲", branch: "子", stemElement: "목", branchElement: "수", isDayPillar: false),
            monthPillar: SajuPillar(stem: "乙", branch: "丑", stemElement: "목", branchElement: "토", isDayPillar: false),
            dayPillar: SajuPillar(stem: "丙", branch: "寅", stemElement: "화", branchElement: "목", isDayPillar: true),
            hourPillar: SajuPillar(stem: "庚", branch: "卯", stemElement: "금", branchElement: "목", isDayPillar: false),
            hourUnknown: false,
            dayMasterNature: "태양",
            investmentTags: "—",
            elementCounts: [.wood: 2, .fire: 1, .earth: 1, .metal: 2, .water: 2]
        )
        let provider = MockTodayDetailProvider(sajuChart: chart)
        XCTAssertNil(provider.weakElement)
    }

    // MARK: - U9: 빈 hapchung 허용 (AC-8)

    func testHapchungEvents_emptyArrayCase() {
        let provider = MockTodayDetailProvider(hapchungEvents: [])
        XCTAssertTrue(provider.hapchungEvents.isEmpty)
    }

    // MARK: - U10: formattedScore signing (AC-10)

    func testFormattedScore_signing() {
        XCTAssertEqual(TodayDetailFormatting.formattedScore(12), "+12")
        XCTAssertEqual(TodayDetailFormatting.formattedScore(-18), "−18")
        // 0 — non-negative branch
        XCTAssertEqual(TodayDetailFormatting.formattedScore(0), "+0")
        // U+2212 (minus sign) 검증
        let negEighteen = TodayDetailFormatting.formattedScore(-18)
        XCTAssertEqual(negEighteen.unicodeScalars.first?.value, 0x2212)
    }

    // MARK: - U11: WuxingElement 한자 매핑 (AC-5 문구)

    func testWuxingHanjaMapping() {
        XCTAssertEqual(WuxingElement.wood.hanja, "木")
        XCTAssertEqual(WuxingElement.fire.hanja, "火")
        XCTAssertEqual(WuxingElement.earth.hanja, "土")
        XCTAssertEqual(WuxingElement.metal.hanja, "金")
        XCTAssertEqual(WuxingElement.water.hanja, "水")
    }
}
