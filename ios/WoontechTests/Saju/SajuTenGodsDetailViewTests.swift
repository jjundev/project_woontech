import XCTest
@testable import Woontech

// MARK: - Stub Provider

private struct StubTenGodsDetailProvider: SajuTenGodsDetailProviding {
    var summaryHeadline: String = "stub headline"
    var summaryBody: String = "stub body"
    var groups: [TenGodGroup] = MockSajuTenGodsDetailProvider.defaultGroups
    var topThree: [CoreTenGod] = MockSajuTenGodsDetailProvider.defaultTopThree
    var absentWarning: AbsentWarning? = MockSajuTenGodsDetailProvider.defaultAbsentWarning
    var learnEntry: LearnEntry? = MockSajuTenGodsDetailProvider.defaultLearnEntry
}

// MARK: - Test Suite

final class SajuTenGodsDetailViewTests: XCTestCase {

    // MARK: Group A — 프로토콜 분리 (AC#17)

    /// T1: `SajuTenGodsDetailProviding`은 `SajuCategoriesProviding`과 별개 타입.
    func test_protocol_tenGodsNotCategories() {
        let tenGodsProvider: any SajuTenGodsDetailProviding = MockSajuTenGodsDetailProvider()
        let categoriesProvider: any SajuCategoriesProviding = MockSajuCategoriesProvider()
        // 두 프로토콜은 완전히 별개의 타입 계층 — 상호 대입 불가 (컴파일 타임 분리).
        // 런타임에서 타입이 다름을 확인.
        XCTAssertFalse(
            type(of: tenGodsProvider) == type(of: categoriesProvider) as Any.Type,
            "SajuTenGodsDetailProviding and SajuCategoriesProviding must be different types"
        )
    }

    /// T2: `SajuTenGodsDetailProviding`은 `SajuElementsDetailProviding`과 별개 타입.
    func test_protocol_tenGodsNotElements() {
        let tenGodsProvider: any SajuTenGodsDetailProviding = MockSajuTenGodsDetailProvider()
        let elementsProvider: any SajuElementsDetailProviding = MockSajuElementsDetailProvider()
        XCTAssertFalse(
            type(of: tenGodsProvider) == type(of: elementsProvider) as Any.Type,
            "SajuTenGodsDetailProviding and SajuElementsDetailProviding must be different types"
        )
    }

    // MARK: Group B — Mock 기본값 (AC#3, AC#11)

    /// T3: summaryHeadline 기본값
    func test_mock_summaryHeadline() {
        let mock = MockSajuTenGodsDetailProvider()
        XCTAssertEqual(mock.summaryHeadline, "정재가 중심인 사주")
    }

    /// T4: summaryBody 비어있지 않음
    func test_mock_summaryBody_notEmpty() {
        let mock = MockSajuTenGodsDetailProvider()
        XCTAssertFalse(mock.summaryBody.isEmpty)
    }

    /// T5: groups 길이 5
    func test_mock_groupsCount5() {
        let mock = MockSajuTenGodsDetailProvider()
        XCTAssertEqual(mock.groups.count, 5)
    }

    /// T6: groups 순서 [비겁, 식상, 재성, 관성, 인성]
    func test_mock_groupsOrder() {
        let mock = MockSajuTenGodsDetailProvider()
        XCTAssertEqual(mock.groups[0].name, "비겁")
        XCTAssertEqual(mock.groups[1].name, "식상")
        XCTAssertEqual(mock.groups[2].name, "재성")
        XCTAssertEqual(mock.groups[3].name, "관성")
        XCTAssertEqual(mock.groups[4].name, "인성")
    }

    /// T7: 재성은 isCore=true
    func test_mock_재성_isCore() {
        let mock = MockSajuTenGodsDetailProvider()
        let 재성 = mock.groups.first { $0.name == "재성" }
        XCTAssertNotNil(재성, "재성 group must exist in mock")
        XCTAssertTrue(재성?.isCore == true, "재성 must be isCore=true in mock")
    }

    /// T8: 식상은 isAbsent=true
    func test_mock_식상_isAbsent() {
        let mock = MockSajuTenGodsDetailProvider()
        let 식상 = mock.groups.first { $0.name == "식상" }
        XCTAssertNotNil(식상, "식상 group must exist in mock")
        XCTAssertTrue(식상?.isAbsent == true, "식상 must be isAbsent=true in mock")
    }

    /// T9: topThree 길이 3
    func test_mock_topThreeCount3() {
        let mock = MockSajuTenGodsDetailProvider()
        XCTAssertEqual(mock.topThree.count, 3)
    }

    /// T10: topThree[0] == 정재, count == 2
    func test_mock_topThree_정재_count2() {
        let mock = MockSajuTenGodsDetailProvider()
        XCTAssertEqual(mock.topThree[0].name, "정재")
        XCTAssertEqual(mock.topThree[0].count, 2)
    }

    /// T11: absentWarning != nil
    func test_mock_absentWarning_notNil() {
        let mock = MockSajuTenGodsDetailProvider()
        XCTAssertNotNil(mock.absentWarning)
    }

    /// T12: absentWarning.groupTitle
    func test_mock_absentWarning_groupTitle() {
        let mock = MockSajuTenGodsDetailProvider()
        XCTAssertEqual(mock.absentWarning?.groupTitle, "식상(식신·상관) 부재")
    }

    /// T13: learnEntry != nil
    func test_mock_learnEntry_notNil() {
        let mock = MockSajuTenGodsDetailProvider()
        XCTAssertNotNil(mock.learnEntry)
    }

    /// T14: learnEntry.lessonId
    func test_mock_learnEntry_lessonId() {
        let mock = MockSajuTenGodsDetailProvider()
        XCTAssertEqual(mock.learnEntry?.lessonId, "L-TEN-001")
    }

    // MARK: Group C — 막대 채움 비율 (AC#7)

    /// T15: total=2 → ≈0.667
    func test_fillRatio_total2_is66pct() {
        let ratio = tenGodsFillRatio(total: 2)
        XCTAssertEqual(ratio, min(2.0 / 3.0, 1.0), accuracy: 0.001)
    }

    /// T16: total=3 → 1.0
    func test_fillRatio_total3_is100pct() {
        let ratio = tenGodsFillRatio(total: 3)
        XCTAssertEqual(ratio, 1.0, accuracy: 0.001)
    }

    /// T17: total=0 → 0.0
    func test_fillRatio_total0_is0pct() {
        let ratio = tenGodsFillRatio(total: 0)
        XCTAssertEqual(ratio, 0.0, accuracy: 0.001)
    }

    /// T18: total=4 → 1.0 (clamped)
    func test_fillRatio_total4_clamped100pct() {
        let ratio = tenGodsFillRatio(total: 4)
        XCTAssertEqual(ratio, 1.0, accuracy: 0.001)
    }

    // MARK: Group D — 표출 십성 텍스트 (AC#8)

    /// T19: counts=[1,0] → "비견"
    func test_displayedItems_oneActive() {
        let result = displayedItems(items: ["비견", "겁재"], counts: [1, 0])
        XCTAssertEqual(result, "비견")
    }

    /// T20: counts=[0,0] → "—"
    func test_displayedItems_allZero() {
        let result = displayedItems(items: ["식신", "상관"], counts: [0, 0])
        XCTAssertEqual(result, "—")
    }

    /// T21: counts=[1,1] → "비견 · 겁재"
    func test_displayedItems_bothActive() {
        let result = displayedItems(items: ["비견", "겁재"], counts: [1, 1])
        XCTAssertEqual(result, "비견 · 겁재")
    }

    // MARK: Group E — precondition / validation (AC#9)

    /// T22: 순서 뒤섞인 5개 배열 → 정렬 성공
    func test_sortedGroups_length5_succeeds() {
        // 순서를 뒤섞은 5개 배열
        let scrambled: [TenGodGroup] = [
            TenGodGroup(name: "인성", han: "印星", meaning: "학문·수용성",
                        items: ["편인", "정인"], counts: [0, 1], total: 1, isCore: false, isAbsent: false),
            TenGodGroup(name: "비겁", han: "比劫", meaning: "주체성·동료",
                        items: ["비견", "겁재"], counts: [1, 0], total: 1, isCore: false, isAbsent: false),
            TenGodGroup(name: "관성", han: "官星", meaning: "명예·규율",
                        items: ["편관", "정관"], counts: [0, 1], total: 1, isCore: false, isAbsent: false),
            TenGodGroup(name: "식상", han: "食傷", meaning: "표현·생산",
                        items: ["식신", "상관"], counts: [0, 0], total: 0, isCore: false, isAbsent: true),
            TenGodGroup(name: "재성", han: "財星", meaning: "재물·실리",
                        items: ["편재", "정재"], counts: [0, 2], total: 2, isCore: true, isAbsent: false),
        ]
        let sorted = sortedTenGodGroups(scrambled)
        XCTAssertEqual(sorted.count, 5)
        XCTAssertEqual(sorted[0].name, "비겁")
        XCTAssertEqual(sorted[1].name, "식상")
        XCTAssertEqual(sorted[2].name, "재성")
        XCTAssertEqual(sorted[3].name, "관성")
        XCTAssertEqual(sorted[4].name, "인성")
    }

    /// T23: 4개 배열 → validateGroups throws
    func test_validateGroups_lengthNot5_throws() {
        let short: [TenGodGroup] = Array(MockSajuTenGodsDetailProvider.defaultGroups.prefix(4))
        XCTAssertThrowsError(try validateGroups(short)) { error in
            if case TenGodsValidationError.invalidGroupCount(let count) = error {
                XCTAssertEqual(count, 4)
            } else {
                XCTFail("Expected invalidGroupCount error, got \(error)")
            }
        }
    }

    /// T24: items.count=1 그룹 → validateGroupLengths throws
    func test_validateGroupLengths_itemsCountNot2_throws() {
        let badGroup = TenGodGroup(
            name: "비겁", han: "比劫", meaning: "주체성·동료",
            items: ["비견"],          // length 1 — invalid
            counts: [1],             // length 1
            total: 1, isCore: false, isAbsent: false
        )
        let groups = [badGroup] + Array(MockSajuTenGodsDetailProvider.defaultGroups.dropFirst())
        XCTAssertThrowsError(try validateGroupLengths(groups)) { error in
            if case TenGodsValidationError.invalidItemsLength(let name) = error {
                XCTAssertEqual(name, "비겁")
            } else {
                XCTFail("Expected invalidItemsLength error, got \(error)")
            }
        }
    }

    // MARK: Group F — topThree validation (AC#10)

    /// T25: 2개 배열 → validateTopThree throws
    func test_validateTopThree_countNot3_throws() {
        let short = Array(MockSajuTenGodsDetailProvider.defaultTopThree.prefix(2))
        XCTAssertThrowsError(try validateTopThree(short)) { error in
            if case TenGodsValidationError.invalidTopThreeCount(let count) = error {
                XCTAssertEqual(count, 2)
            } else {
                XCTFail("Expected invalidTopThreeCount error, got \(error)")
            }
        }
    }

    // MARK: Group G — Optional 카드 nil/non-nil (AC#12–15)

    /// T26: absentWarning != nil → View 생성 crash 없음
    func test_absentWarningNonNil_viewCreates() {
        let provider = MockSajuTenGodsDetailProvider()
        XCTAssertNotNil(provider.absentWarning)
        let _ = SajuTenGodsDetailView(provider: provider, onNavigate: { _ in })
    }

    /// T27: absentWarning = nil → View 생성 crash 없음
    func test_absentWarningNil_viewCreates() {
        let provider = MockSajuTenGodsDetailProvider(absentWarning: nil)
        XCTAssertNil(provider.absentWarning)
        let _ = SajuTenGodsDetailView(provider: provider, onNavigate: { _ in })
    }

    /// T28: learnEntry != nil → View 생성 crash 없음
    func test_learnEntryNonNil_viewCreates() {
        let provider = MockSajuTenGodsDetailProvider()
        XCTAssertNotNil(provider.learnEntry)
        let _ = SajuTenGodsDetailView(provider: provider, onNavigate: { _ in })
    }

    /// T29: learnEntry = nil → View 생성 crash 없음
    func test_learnEntryNil_viewCreates() {
        let provider = MockSajuTenGodsDetailProvider(learnEntry: nil)
        XCTAssertNil(provider.learnEntry)
        let _ = SajuTenGodsDetailView(provider: provider, onNavigate: { _ in })
    }

    // MARK: Group H — SajuTabDependencies 통합 (AC#17)

    /// T30: Stub provider 주입 → summaryHeadline 반영
    func test_deps_tenGodsDetailReplaceable() {
        let stub = StubTenGodsDetailProvider(summaryHeadline: "stub")
        let deps = SajuTabDependencies(tenGodsDetail: stub)
        XCTAssertEqual(deps.tenGodsDetail.summaryHeadline, "stub",
                       "Custom tenGodsDetail provider must be reflected in SajuTabDependencies")
    }
}
