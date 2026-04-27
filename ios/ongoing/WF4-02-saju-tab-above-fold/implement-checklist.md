# Implementation Checklist — WF4-02 사주 탭 Above-the-Fold

> Authoritative checklist for the implementor and code reviewer.  
> Source: `spec.md` (18 AC) + `implement-plan.md` v2.  
> Mark each item ☑ when verified.

---

## Requirements (from spec)

- [ ] R1 (AC1): `SajuTabView` 컨텐츠 슬롯 최상단에 원국 카드, 그 아래 "내 사주 자세히" 섹션 헤더와 5개 카테고리 카드가 순서대로 렌더된다.
- [ ] R2 (AC2): 4기둥 셀이 항상 `[時, 日, 月, 年]` 순서로 표시된다(provider 데이터 순서와 무관하게 position 키로 정렬).
- [ ] R3 (AC3): `MockUserSajuOriginProvider` 기본값 주입 시 4기둥에 `時庚申 / 日丙午 / 月辛卯 / 年庚午` 가 표시된다.
- [ ] R4 (AC4): 일간(日의 천간) 셀 배경이 `DesignTokens.dayMasterHighlight` 토큰으로 강조되며 나머지 셀과 시각적으로 구분된다.
- [ ] R5 (AC5): 일간 한줄 박스에 `UserSajuOriginProviding.dayMasterLine` 값이 그대로 렌더된다.
- [ ] R6 (AC6): `pillars.count != 4`인 mock 주입 시 `precondition` 실패(런타임 fatalError)가 명시적으로 발생한다.
- [ ] R7 (AC7): "내 사주 자세히" 섹션은 항상 `[오행 분포, 십성 분석, 대운 · 세운, 합충형파, 용신 · 희신]` 순서로 5슬롯을 렌더하며, 데이터 누락 시 "데이터 없음" placeholder를 표시한다.
- [ ] R8 (AC8): 각 카테고리 카드는 `summary`와 `badge`(존재 시)를 바인딩하고, `badge == nil`이면 badge UI 자체가 숨겨진다.
- [ ] R9 (AC9): "오행 분포" 카드 탭 → `SajuRoute.elements`가 NavigationStack path에 append된다.
- [ ] R10 (AC10): "십성 분석" 카드 탭 → `SajuRoute.tenGods`가 path에 append된다.
- [ ] R11 (AC11): "대운 · 세운" 카드 탭 → `SajuRoute.daewoonPlaceholder`가 path에 append된다.
- [ ] R12 (AC12): "합충형파" 카드 탭 → `SajuRoute.hapchungPlaceholder`가 path에 append된다.
- [ ] R13 (AC13): "용신 · 희신" 카드 탭 → `SajuRoute.yongsinPlaceholder`가 path에 append된다.
- [ ] R14 (AC14): "근거 보기" 영역 단독 탭도 카드 전체 탭과 동일한 라우트를 push한다(단일 hit-test, 별도 `onTapGesture` 불필요).
- [ ] R15 (AC15): "전체 보기 ›" 탭은 path를 변경하지 않으며(no-op), VoiceOver hint에 "준비중"이 노출된다.
- [ ] R16 (AC16): Dynamic Type XL에서 카테고리 카드 summary/badge가 wrapping되어 잘리지 않는다.
- [ ] R17 (AC17): VoiceOver focus가 일간 셀에 닿으면 `.isHeader` 트레잇과 함께 "{기둥명}, 천간 {한자}, 지지 {한자}" 형식이 읽힌다.
- [ ] R18 (AC18): 5개 카테고리 카드 각각의 hit target이 44×44pt 이상이다.

---

## Implementation Steps

- [ ] S0: `UserSajuOriginProviding.swift`와 `SajuCategoriesProviding.swift`에서 mock 기본값 확인 및 보완
  - `MockUserSajuOriginProvider.pillars` = `[時庚申, 日丙午, 月辛卯, 年庚午]` (4개 정확히)
  - `MockUserSajuOriginProvider.dayMasterLine` = `"일간 丙火 · 양의 불 — 따뜻함, 표현력, 리더십"`
  - `MockSajuCategoriesProvider.categories` = 스펙 5슬롯(오행 badge "부족: 水", 대운 badge "전환기", 나머지 badge nil)
  - 값이 이미 올바르면 수정 불필요

- [ ] S1: `Woontech/Shared/DesignTokens.swift`에 두 토큰 추가
  - `static let dayMasterHighlight` — 일간 천간 셀 강조 배경 (`#D6D6D6` / `gray2` 재사용)
  - `static let dayMasterLineBg` — 일간 한줄 박스 배경 (`#F2F2F2` / `gray` 재사용)

- [ ] S2: `Woontech/Features/Saju/AboveFold/SajuPillarCellView.swift` 신규 작성
  - 입력: `pillar: Pillar`, `columnLabel: String`, `isDayMaster: Bool`
  - 천간 박스 배경: `isDayMaster ? DesignTokens.dayMasterHighlight : DesignTokens.bg`
  - `.accessibilityElement(children: .ignore)` + 통합 accessibility label
  - `isDayMaster` 시 `.accessibilityAddTraits(.isHeader)` 추가
  - `accessibilityIdentifier("SajuPillarCell_\(pillar.position.rawValue)")`

- [ ] S3: `Woontech/Features/Saju/AboveFold/SajuOriginCardView.swift` 신규 작성
  - 입력: `provider: any UserSajuOriginProviding`, `onViewAll: () -> Void`
  - `body` 진입 시 `precondition(provider.pillars.count == 4, ...)`
  - `displayOrder: [Pillar.Position] = [.hour, .day, .month, .year]`
  - `pillarMap` = `Dictionary(uniqueKeysWithValues: provider.pillars.map { ($0.position, $0) })`
  - "내 사주 원국" `Text`에 `.accessibilityIdentifier("SajuOriginCardHeaderLabel")` 포함
  - "전체 보기 ›" 버튼에 `.accessibilityHint("준비중")` 및 identifier `"SajuOriginCardViewAllButton"`
  - 일간 한줄 박스: `.accessibilityIdentifier("SajuDayMasterLine")`, `fixedSize(horizontal: false, vertical: true)`
  - 카드 외곽: `.accessibilityIdentifier("SajuOriginCard")`

- [ ] S4: `Woontech/Features/Saju/AboveFold/SajuCategoryCardView.swift` 신규 작성
  - 입력: `summary: SajuCategorySummary?`, `kind: SajuCategorySummary.Kind`, `onTap: () -> Void`
  - `summary == nil` → "데이터 없음" placeholder (height ≥ 44pt)
  - `Button(action: onTap)` 전체 영역 래핑(좌측 텍스트 + 우측 chevron/"근거 보기" 포함)
  - `badge` 조건부 렌더: `if let badge = summary.badge { ... }`
  - `.frame(minHeight: 44)` + `.contentShape(Rectangle())`
  - accessibility label: `"\(summary.title), \(summary.summary)\(summary.badge.map { ", \($0) 표시" } ?? "")"`
  - **구현 주의**: `summary.title`은 `SajuCategorySummary.Kind`의 computed property — WF4-01에 없으면 추가
    - `.elements` → "오행 분포", `.tenGods` → "십성 분석", `.daewoon` → "대운 · 세운", `.hapchung` → "합충형파", `.yongsin` → "용신 · 희신"
  - identifier: `"SajuCategoryCard_\(kind.rawValue)"`, badge: `"SajuCategoryBadge_\(kind.rawValue)"`, 근거: `"SajuCategoryEvidence_\(kind.rawValue)"`

- [ ] S5: `Woontech/Features/Saju/AboveFold/SajuCategoriesSection.swift` 신규 작성
  - `displayOrder: [SajuCategorySummary.Kind] = [.elements, .tenGods, .daewoon, .hapchung, .yongsin]`
  - `route(for:)` 매핑: `.elements`→`.elements`, `.tenGods`→`.tenGods`, `.daewoon`→`.daewoonPlaceholder`, `.hapchung`→`.hapchungPlaceholder`, `.yongsin`→`.yongsinPlaceholder`
  - 섹션 헤더 identifier: `"SajuDetailSectionHeader"`
  - provider에 없는 kind는 `nil` → `SajuCategoryCardView` placeholder

- [ ] S6: `Woontech/Features/Saju/SajuTabContentView.swift` 신규 작성
  - `ScrollView` 안에 `SajuOriginCardView` + `SajuCategoriesSection` (16pt top padding)
  - `onViewAll: { /* no-op */ }` 전달
  - WF4-03 공간 예약 `Spacer(minLength: 32)` 포함
  - identifier: `"SajuTabContent"`

- [ ] S7: `Woontech/Features/Saju/SajuTabView.swift` 수정
  - `SajuTabContentPlaceholderView()` → `SajuTabContentView(originProvider:categoriesProvider:onNavigate:)` 교체
  - `SajuTabContentPlaceholderView.swift` 파일 자체는 삭제 금지(WF4-01 잔여 참조 가능)
  - WF4-01의 `SajuTabFoundationUITests.test_sajuContent_placeholderVisible()` (T17)을 `XCTSkip` 또는 삭제 처리

- [ ] S8: 모든 accessibility identifier가 Step 8 테이블 값과 정확히 일치하는지 검토
  - `SajuTabContent`, `SajuOriginCard`, `SajuOriginCardHeaderLabel`, `SajuOriginCardViewAllButton`
  - `SajuPillarCell_{hour|day|month|year}`, `SajuDayMasterLine`
  - `SajuDetailSectionHeader`
  - `SajuCategoryCard_{elements|tenGods|daewoon|hapchung|yongsin}`
  - `SajuCategoryBadge_{kind}`, `SajuCategoryEvidence_{kind}`

---

## Tests

### Unit Tests (`WoontechTests/Saju/SajuAboveFoldTests.swift`)

- [ ] T1 (unit) TA-01: `test_pillarDisplayOrder_isFixed_時日月年` — `displayOrder == [.hour, .day, .month, .year]` (AC2)
- [ ] T2 (unit) TA-02: `test_mockOriginProvider_defaultPillars_containsDay丙午` — `.day` 기둥 `heavenlyStem == "丙"`, `earthlyBranch == "午"` (AC3)
- [ ] T3 (unit) TA-03: `test_mockOriginProvider_defaultPillars_containsHour庚申` — `.hour` 기둥 `heavenlyStem == "庚"`, `earthlyBranch == "申"` (AC3)
- [ ] T4 (unit) TA-04: `test_mockOriginProvider_defaultPillars_containsMonth辛卯` — `.month` 기둥 `heavenlyStem == "辛"`, `earthlyBranch == "卯"` (AC3)
- [ ] T5 (unit) TA-05: `test_mockOriginProvider_defaultPillars_containsYear庚午` — `.year` 기둥 `heavenlyStem == "庚"`, `earthlyBranch == "午"` (AC3)
- [ ] T6 (unit) TA-06: `test_mockOriginProvider_dayMasterLine_contains丙火` — `dayMasterLine`에 "丙火" 포함 (AC5)
- [ ] T7 (unit) TA-07: `test_originCard_pillarMap_builtCorrectly` — `pillarMap` 4키 존재, `.day` → `heavenlyStem == "丙"` (AC3)
- [ ] T8 (unit) TA-08: `test_originCard_precondition_failsForWrongCount` — `pillars.count != 4` 시 런타임 fatalError 사실을 명시(`XCTExpectFailure` 또는 주석 문서화) (AC6)
- [ ] T9 (unit) TA-09: `test_categoriesSection_displayOrder_isFixed` — `[.elements, .tenGods, .daewoon, .hapchung, .yongsin]` (AC7)
- [ ] T10 (unit) TA-10: `test_categoriesSection_routeMapping_elements→elements` (AC9)
- [ ] T11 (unit) TA-11: `test_categoriesSection_routeMapping_tenGods→tenGods` (AC10)
- [ ] T12 (unit) TA-12: `test_categoriesSection_routeMapping_daewoon→daewoonPlaceholder` (AC11)
- [ ] T13 (unit) TA-13: `test_categoriesSection_routeMapping_hapchung→hapchungPlaceholder` (AC12)
- [ ] T14 (unit) TA-14: `test_categoriesSection_routeMapping_yongsin→yongsinPlaceholder` (AC13)
- [ ] T15 (unit) TA-15: `test_categoryCard_badge_nilWhenMockHasNil` — `.tenGods` badge == nil (AC8)
- [ ] T16 (unit) TA-16: `test_categoryCard_badge_nonNilWhenMockHasBadge` — `.elements` badge == "부족: 水", `.daewoon` badge == "전환기" (AC8)
- [ ] T17 (unit) TA-17: `test_categoriesSection_missingSlot_usesPlaceholder` — 빈 categories 주입 시 모든 5슬롯 lookup 결과 nil (AC7)
- [ ] T18 (unit) TA-18: `test_pillarCell_isDayMaster_trueOnlyForDay` — `displayOrder`에서 `.day`만 `isDayMaster: true` (AC4)
- [ ] T19 (unit) TA-19: `test_columnLabel_매핑` — `label(for:)` hour→"時", day→"日", month→"月", year→"年" (AC2)

### UI Tests (`WoontechUITests/Saju/SajuAboveFoldUITests.swift`)

- [ ] T20 (ui) TU-01: `test_originCard_existsAtTopOfContent` — `SajuOriginCard` waitForExistence (AC1)
- [ ] T21 (ui) TU-02: `test_originCard_headerLabel_내사주원국` — `SajuOriginCardHeaderLabel.label == "내 사주 원국"` (AC1)
- [ ] T22 (ui) TU-03: `test_pillarCells_allFourExist` — 4개 `SajuPillarCell_{position}` 모두 exists (AC2)
- [ ] T23 (ui) TU-04: `test_pillarCells_day_has丙午_inLabel` — `SajuPillarCell_day.label`에 "日", "丙", "午" 포함 (AC3)
- [ ] T24 (ui) TU-05: `test_pillarCells_hour_has庚申` — `SajuPillarCell_hour.label`에 "庚", "申" 포함 (AC3)
- [ ] T25 (ui) TU-06: `test_dayMasterLine_text_contains丙火` — `staticTexts["SajuDayMasterLine"].label`에 "丙火" 포함 (AC5)
- [ ] T26 (ui) TU-07: `test_dayMasterCell_hasIsHeaderTrait` — `SajuPillarCell_day` accessibility traits에 `.isHeader` 포함 (AC4, AC17)
- [ ] T27 (ui) TU-08: `test_viewAllButton_noopDoesNotPush` — `SajuOriginCardViewAllButton` 탭 후 path 변경 없음 (AC15)
- [ ] T28 (ui) TU-09: `test_viewAllButton_accessibilityHint_준비중` — `SajuOriginCardViewAllButton.accessibilityHint == "준비중"` (AC15)
- [ ] T29 (ui) TU-10: `test_detailSectionHeader_exists` — `staticTexts["SajuDetailSectionHeader"].exists` (AC1, AC7)
- [ ] T30 (ui) TU-11: `test_allFiveCategoryCards_exist` — 5개 `SajuCategoryCard_{kind}` 모두 exists (AC7)
- [ ] T31 (ui) TU-12: `test_categoryCard_elements_summary` — label에 "오행 분포", "火 3" 포함 (AC8)
- [ ] T32 (ui) TU-13: `test_categoryCard_badge_elements_부족水_exists` — `SajuCategoryBadge_elements.exists`, label == "부족: 水" (AC8)
- [ ] T33 (ui) TU-14: `test_categoryCard_badge_tenGods_hidden` — `SajuCategoryBadge_tenGods.exists == false` (AC8)
- [ ] T34 (ui) TU-15: `test_categoryCard_elements_tap_pushesElements` — 탭 → `SajuPlaceholderDestination_elements` 출현 (AC9)
- [ ] T35 (ui) TU-16: `test_categoryCard_tenGods_tap_pushesTenGods` (AC10)
- [ ] T36 (ui) TU-17: `test_categoryCard_daewoon_tap_pushesDaewoon` (AC11)
- [ ] T37 (ui) TU-18: `test_categoryCard_hapchung_tap_pushesHapchung` (AC12)
- [ ] T38 (ui) TU-19: `test_categoryCard_yongsin_tap_pushesYongsin` (AC13)
- [ ] T39 (ui) TU-20: `test_evidence근거보기_tap_sameAsCardTap` — `SajuCategoryEvidence_elements` 탭 → 동일 destination (AC14)
- [ ] T40 (ui) TU-21: `test_dynamicType_xl_categoryCard_summaryNotTruncated` — XL 환경에서 카드 height > 44 (AC16)
- [ ] T41 (ui) TU-22: `test_categoryCard_hitTarget_minHeight44` — 5개 카드 각각 `frame.height >= 44` (AC18)

---

## Implementation Notes

1. **`SajuCategorySummary.Kind.title` 존재 확인**: `SajuCategoryCardView`에서 `summary.title`을 참조한다. WF4-01 선언에 `title` computed property가 없으면 `SajuCategoriesProviding.swift`에 extension으로 추가(`.elements`→"오행 분포", `.tenGods`→"십성 분석", `.daewoon`→"대운 · 세운", `.hapchung`→"합충형파", `.yongsin`→"용신 · 희신").
2. **WF4-01 placeholder 테스트 처리**: `SajuTabFoundationUITests.test_sajuContent_placeholderVisible()`(T17)는 교체 후 깨지므로 `XCTSkip` 또는 삭제 필요.
3. **Dynamic Type 4-column 겹침 위험**: 원국 4-column HStack이 XL에서 overlap 될 경우 천간/지지 박스에 `fixedSize(horizontal: false, vertical: true)` 추가 또는 `LazyVGrid` 전환 검토.
4. **"근거 보기" hit-test**: `Text` 가 `Button` 내부에 포함되므로 별도 gesture 불필요. 빌드 후 TU-20 실행으로 검증.
5. **precondition 테스트(TA-08)**: Swift `precondition`은 XCTest에서 포착 불가. TA-08은 코드 주석으로 fatalError 발생 사실을 문서화하고, mock 주입 제한으로 런타임 보장.
