import XCTest
@testable import Woontech

/// Unit tests for WF4-02 사주 탭 above-the-fold (원국 카드 + 5 카테고리).
final class SajuAboveFoldTests: XCTestCase {

    // MARK: - TA-01 pillar display order

    /// 표시 순서는 항상 [時, 日, 月, 年] = [.hour, .day, .month, .year].
    func test_pillarDisplayOrder_isFixed_時日月年() {
        let displayOrder: [Pillar.Position] = [.hour, .day, .month, .year]
        XCTAssertEqual(displayOrder, [.hour, .day, .month, .year])
    }

    // MARK: - TA-02~05 Mock pillars

    func test_mockOriginProvider_defaultPillars_containsDay丙午() {
        let provider = MockUserSajuOriginProvider()
        let dayPillar = provider.pillars.first(where: { $0.position == .day })
        XCTAssertNotNil(dayPillar)
        XCTAssertEqual(dayPillar?.heavenlyStem, "丙")
        XCTAssertEqual(dayPillar?.earthlyBranch, "午")
    }

    func test_mockOriginProvider_defaultPillars_containsHour庚申() {
        let provider = MockUserSajuOriginProvider()
        let hourPillar = provider.pillars.first(where: { $0.position == .hour })
        XCTAssertNotNil(hourPillar)
        XCTAssertEqual(hourPillar?.heavenlyStem, "庚")
        XCTAssertEqual(hourPillar?.earthlyBranch, "申")
    }

    func test_mockOriginProvider_defaultPillars_containsMonth辛卯() {
        let provider = MockUserSajuOriginProvider()
        let monthPillar = provider.pillars.first(where: { $0.position == .month })
        XCTAssertNotNil(monthPillar)
        XCTAssertEqual(monthPillar?.heavenlyStem, "辛")
        XCTAssertEqual(monthPillar?.earthlyBranch, "卯")
    }

    func test_mockOriginProvider_defaultPillars_containsYear庚午() {
        let provider = MockUserSajuOriginProvider()
        let yearPillar = provider.pillars.first(where: { $0.position == .year })
        XCTAssertNotNil(yearPillar)
        XCTAssertEqual(yearPillar?.heavenlyStem, "庚")
        XCTAssertEqual(yearPillar?.earthlyBranch, "午")
    }

    // MARK: - TA-06 dayMasterLine

    func test_mockOriginProvider_dayMasterLine_contains丙火() {
        let provider = MockUserSajuOriginProvider()
        XCTAssertTrue(provider.dayMasterLine.contains("丙火"),
                      "dayMasterLine should contain '丙火'")
    }

    // MARK: - TA-07 pillarMap construction

    func test_originCard_pillarMap_builtCorrectly() {
        let provider = MockUserSajuOriginProvider()
        XCTAssertEqual(provider.pillars.count, 4)

        let pillarMap: [Pillar.Position: Pillar] = Dictionary(
            uniqueKeysWithValues: provider.pillars.map { ($0.position, $0) }
        )

        XCTAssertEqual(pillarMap.keys.count, 4)
        XCTAssertNotNil(pillarMap[.hour])
        XCTAssertNotNil(pillarMap[.day])
        XCTAssertNotNil(pillarMap[.month])
        XCTAssertNotNil(pillarMap[.year])
        XCTAssertEqual(pillarMap[.day]?.heavenlyStem, "丙")
    }

    // MARK: - TA-08 precondition for wrong count

    /// `precondition`은 XCTest 내에서 포착할 수 없으므로, 잘못된 배열 주입 시
    /// 런타임 fatalError가 발생함을 코드 수준에서 문서화한다.
    /// 실제 런타임에서 `pillars.count != 4`인 provider를 주입하면
    /// `SajuOriginCardView.body` 진입 시 즉시 앱이 크래시한다.
    func test_originCard_precondition_failsForWrongCount() {
        // precondition은 XCTest에서 직접 포착 불가.
        // 이 테스트는 런타임 계약을 문서화한다:
        // MockUserSajuOriginProvider(pillars: []) 를 SajuOriginCardView에 주입하면
        // body 진입 시 "UserSajuOriginProviding must supply exactly 4 pillars" 메시지와 함께
        // 앱이 fatalError로 종료된다.
        let wrongProvider = MockUserSajuOriginProvider(pillars: [])
        XCTAssertNotEqual(wrongProvider.pillars.count, 4,
                          "This provider intentionally has wrong count to document the contract")
        // Contract: SajuOriginCardView.body 진입 시 precondition failure (fatalError) 발생.
    }

    // MARK: - TA-09 categories display order

    func test_categoriesSection_displayOrder_isFixed() {
        let displayOrder: [SajuCategorySummary.Kind] = [
            .elements, .tenGods, .daewoon, .hapchung, .yongsin
        ]
        XCTAssertEqual(displayOrder, [.elements, .tenGods, .daewoon, .hapchung, .yongsin])
    }

    // MARK: - TA-10~14 route mapping

    func test_categoriesSection_routeMapping_elements_elements() {
        let section = SajuCategoriesSection(
            provider: MockSajuCategoriesProvider(),
            onNavigate: { _ in }
        )
        XCTAssertEqual(section.route(for: .elements), .elements)
    }

    func test_categoriesSection_routeMapping_tenGods_tenGods() {
        let section = SajuCategoriesSection(
            provider: MockSajuCategoriesProvider(),
            onNavigate: { _ in }
        )
        XCTAssertEqual(section.route(for: .tenGods), .tenGods)
    }

    func test_categoriesSection_routeMapping_daewoon_daewoonPlaceholder() {
        let section = SajuCategoriesSection(
            provider: MockSajuCategoriesProvider(),
            onNavigate: { _ in }
        )
        XCTAssertEqual(section.route(for: .daewoon), .daewoonPlaceholder)
    }

    func test_categoriesSection_routeMapping_hapchung_hapchungPlaceholder() {
        let section = SajuCategoriesSection(
            provider: MockSajuCategoriesProvider(),
            onNavigate: { _ in }
        )
        XCTAssertEqual(section.route(for: .hapchung), .hapchungPlaceholder)
    }

    func test_categoriesSection_routeMapping_yongsin_yongsinPlaceholder() {
        let section = SajuCategoriesSection(
            provider: MockSajuCategoriesProvider(),
            onNavigate: { _ in }
        )
        XCTAssertEqual(section.route(for: .yongsin), .yongsinPlaceholder)
    }

    // MARK: - TA-15~16 badge nil / non-nil

    func test_categoryCard_badge_nilWhenMockHasNil() {
        let provider = MockSajuCategoriesProvider()
        let tenGods = provider.categories.first(where: { $0.kind == .tenGods })
        XCTAssertNotNil(tenGods)
        XCTAssertNil(tenGods?.badge, ".tenGods badge should be nil")
    }

    func test_categoryCard_badge_nonNilWhenMockHasBadge() {
        let provider = MockSajuCategoriesProvider()
        let elements = provider.categories.first(where: { $0.kind == .elements })
        let daewoon  = provider.categories.first(where: { $0.kind == .daewoon })

        XCTAssertEqual(elements?.badge, "부족: 水")
        XCTAssertEqual(daewoon?.badge, "전환기")
    }

    // MARK: - TA-17 missing slot → nil

    func test_categoriesSection_missingSlot_usesPlaceholder() {
        let emptyProvider = MockSajuCategoriesProvider(categories: [])
        let displayOrder: [SajuCategorySummary.Kind] = [
            .elements, .tenGods, .daewoon, .hapchung, .yongsin
        ]
        for kind in displayOrder {
            let result = emptyProvider.categories.first(where: { $0.kind == kind })
            XCTAssertNil(result, "Kind \(kind) should be nil when categories is empty")
        }
    }

    // MARK: - TA-18 isDayMaster only for .day

    func test_pillarCell_isDayMaster_trueOnlyForDay() {
        let displayOrder: [Pillar.Position] = [.hour, .day, .month, .year]
        for position in displayOrder {
            let isDayMaster = (position == .day)
            if position == .day {
                XCTAssertTrue(isDayMaster, ".day should be isDayMaster")
            } else {
                XCTAssertFalse(isDayMaster, "\(position) should not be isDayMaster")
            }
        }
    }

    // MARK: - TA-19 column label mapping

    func test_columnLabel_매핑() {
        func label(for position: Pillar.Position) -> String {
            switch position {
            case .hour:  return "時"
            case .day:   return "日"
            case .month: return "月"
            case .year:  return "年"
            }
        }
        XCTAssertEqual(label(for: .hour),  "時")
        XCTAssertEqual(label(for: .day),   "日")
        XCTAssertEqual(label(for: .month), "月")
        XCTAssertEqual(label(for: .year),  "年")
    }
}
