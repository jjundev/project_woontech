# Implementation Checklist

## Requirements (from spec)

- [ ] R1 (AC-1): Insights "일진" 카드 탭 시 `TodayDetailView`가 push된다 (`HomeRoute.today` 라우트 연결).
- [ ] R2 (AC-2): NavBar 타이틀 "오늘의 일진" + Back 탭 시 pop.
- [ ] R3 (AC-3): 사주 원국 카드는 `TodayDetailProviding.sajuChart`의 4기둥(년/월/일/시) 및 오행 분포를 렌더한다.
- [ ] R4 (AC-4): 오행 분포 바는 항상 5칸을 목·화·토·금·수 순서로 표시하며 각 칸의 카운트가 `sajuChart`를 반영한다.
- [ ] R5 (AC-5): `weakElement == .water` 일 때 "水 부족 → 水 기운의 날 주의" 문구 노출, nil이면 숨김.
- [ ] R6 (AC-6): 십성 stamp에 `sipseong.name`(한글 bold) + `sipseong.hanja`(한자 caption) 노출.
- [ ] R7 (AC-7): 십성 카드 우측에 `oneLiner`, `relation`, `examples` 3줄 표시.
- [ ] R8 (AC-8): 합충 카드는 `hapchungEvents` 순서대로 row 렌더; 배열이 비어 있으면 카드(헤더 포함)가 숨김.
- [ ] R9 (AC-9): impact=negative row는 점선 border + 빨강 텍스트/border 스타일.
- [ ] R10 (AC-10): score 양수는 "+12", 음수는 "−18"(U+2212) 부호 포함 표시.
- [ ] R11 (AC-11): `dailyMotto` / `dailyTaboo` non-nil일 때만 각 카드 노출, nil이면 숨김.
- [ ] R12 (AC-12): Disclaimer가 ScrollView 최하단 요소로 존재.
- [ ] R13 (AC-13): `TodayDetailProviding`을 사용자 정의 mock으로 교체하면 사주 원국·십성·합충 모든 필드가 반영(단위 테스트).
- [ ] R14 (AC-14): Dynamic Type XL에서 합충 row 텍스트 wrapping, score 잘림 없음(UI 테스트).
- [ ] R15 (AC-15): 사주 원국 차트 렌더에 `SajuMiniChartView` 재사용(import/참조 확인).

## Implementation steps

- [ ] S1: `TodayDetailProviding.swift` 신규 작성 — 모델(`SajuChartData`, `SipseongInfo`, `HapchungEvent`, `HapchungBranch`, `HapchungImpact`) + `protocol TodayDetailProviding` + `MockTodayDetailProvider`(부분 override 가능한 default-arg init) + `WuxingElement.hanja` extension.
- [ ] S2: `HomeDependencies`에 `todayDetail: any TodayDetailProviding` + `MockTodayDetailProvider()` 기본값 추가.
- [ ] S3: `TodayDetailView.swift` 메인 뷰 + 카드 sub-views 작성 (`SajuOriginCard`, `WuxingDistributionRow`, `SipseongCard`, `HapchungCard`, `HapchungRowView`, `MottoCard`, `TabooCard`).
- [ ] S4: 사주 원국 카드 — `SajuMiniChartView` 재사용(카운트→Double 정규화, `strongElements`/`supplementElements`/`investmentTags`/`dayMasterNature` 필요값 채움) + `WuxingDistributionRow`(5칸 한글·한자·숫자) + `weakElement` 경고 문구.
- [ ] S5: 십성 카드 — 좌측 56×56 검정 stamp(name bold + hanja caption, white text) + 우측 oneLiner / relation / examples.
- [ ] S6: 합충 카드 — 빈 배열일 때 카드 자체 비표시; 헤더 + 범례 "합(+) · 충(−)"; row(branch1 + 기호 +/↔ + branch2 + kind 배지 + score); positive 실선/negative 점선 + 빨강(`DesignTokens.fireColor`); `formattedScore(_:)` helper로 부호 포맷; `.fixedSize(horizontal:false, vertical:true)` + `.layoutPriority(1)` 잘림 방지; row VoiceOver label 부여.
- [ ] S7: 옵션 카드(MottoCard / TabooCard) — provider 값 non-nil일 때만 렌더.
- [ ] S8: `DisclaimerView()` 푸터 재사용.
- [ ] S9: NavBar — `InvestingAttitudeDetailView` 패턴(custom HStack + chevron.left + `dismiss`) 사용; identifiers `TodayDetailTitle` / `TodayDetailBackButton`.
- [ ] S10: `HomeDashboardView` `.today` 케이스를 `TodayDetailView(provider: homeDeps.todayDetail)`로 교체. hidden trigger button(`HomeNavPushToday`) 유지.
- [ ] S11: `HomeRouteDestinations.swift`의 `TodayPlaceholderView`에 `@available(*, deprecated)` 마커 부착(보존).
- [ ] S12: `WoontechApp.swift` 인자 파싱 블록에 `-mockTodayHapchungEmpty`, `-mockTodayMottoTabooOn` 두 플래그 추가 → `HomeDependencies.todayDetail` 교체 헬퍼 호출.
- [ ] S13: `#Preview` — `NavigationStack { TodayDetailView(provider: MockTodayDetailProvider()) }`.

## Tests

### Unit tests (`WoontechTests/Home/TodayDetailViewTests.swift`)

- [ ] T1 (unit) U1: `testMockProviderDefaults_sajuChartPillars` — 4기둥 stem/branch가 와이어프레임 값 (AC-3).
- [ ] T2 (unit) U2: `testMockProviderDefaults_elementCounts` — `[wood:1, fire:3, earth:1, metal:3, water:0]` (AC-4).
- [ ] T3 (unit) U3: `testMockProviderDefaults_weakElementIsWater` — `.water` (AC-5).
- [ ] T4 (unit) U4: `testMockProviderDefaults_sipseong` — name "편관"/hanja "偏官"/oneLiner/relation/examples 모두 non-empty (AC-6, AC-7).
- [ ] T5 (unit) U5: `testMockProviderDefaults_hapchungEvents` — 2개, [+12 positive 申/巳, −18 negative 卯/酉] (AC-9, AC-10).
- [ ] T6 (unit) U6: `testMockProviderDefaults_dailyMottoTabooNil` — 둘 다 nil 기본 (AC-11).
- [ ] T7 (unit) U7: `testCustomProvider_overridesAllFields` — 사용자 정의 mock의 sajuChart·sipseong·hapchung 모든 필드 반영 (AC-13).
- [ ] T8 (unit) U8: `testWeakElementNilWhenAllElementsPresent` — 카운트 모두 ≥1 → `weakElement == nil` (AC-5 부정).
- [ ] T9 (unit) U9: `testHapchungEvents_emptyArrayCase` — 빈 배열 허용 (AC-8).
- [ ] T10 (unit) U10: `testFormattedScore_signing` — `formattedScore(12) == "+12"`, `formattedScore(-18) == "−18"`(U+2212) (AC-10).
- [ ] T11 (unit) U11: `testWuxingHanjaMapping` — `WuxingElement → "木"·"火"·"土"·"金"·"水"` (AC-5 문구).

### UI tests (`WoontechUITests/Home/TodayDetailUITests.swift`)

- [ ] T12 (ui) UI1: `testInsightsTodayCardTap_pushesTodayDetail` — `HomeInsightsCard_1` 탭 → `TodayDetailTitle` 노출 (AC-1).
- [ ] T13 (ui) UI2: `testNavBarTitleAndBack` — title "오늘의 일진"; Back → `HomeDashboardRoot` 복귀 (AC-2).
- [ ] T14 (ui) UI3: `testSajuOriginRendersFourPillars` — `SajuPillar_year/_month/_day/_hour` 모두 존재 (AC-3, AC-15).
- [ ] T15 (ui) UI4: `testWuxingDistributionFiveCellsOrder` — `WuxingCell_wood/_fire/_earth/_metal/_water` 모두 존재, 한자+숫자 포함 (AC-4).
- [ ] T16 (ui) UI5: `testWeakElementWarningRendered` — `WuxingWarningText` 라벨에 "水 부족" 포함 (AC-5).
- [ ] T17 (ui) UI6: `testSipseongStamp` — `SipseongStampName.label == "편관"`, `SipseongStampHanja.label == "偏官"` (AC-6).
- [ ] T18 (ui) UI7: `testSipseongRightSideThreeLines` — `SipseongOneLiner`, `SipseongRelation`, `SipseongExamples` 모두 존재 (AC-7).
- [ ] T19 (ui) UI8: `testHapchungRowsRenderInOrder` — `HapchungRow_0`(申/巳), `HapchungRow_1`(卯/酉) 순서 (AC-8).
- [ ] T20 (ui) UI9: `testHapchungCardHiddenWhenEmpty` — `-mockTodayHapchungEmpty` 인자로 mock swap, `HapchungSection` 비표시 (AC-8).
- [ ] T21 (ui) UI10: `testHapchungNegativeRowStyling` — `HapchungRow_1`의 score "−18" 포함, `HapchungRow_1_NegativeStyle` 식별자 존재 (AC-9).
- [ ] T22 (ui) UI11: `testHapchungScoreFormatting` — 양수 row "+12", 음수 row "−18" 포함 (AC-10).
- [ ] T23 (ui) UI12: `testDailyMottoTabooHidden_whenNil` — 기본 mock에서 `DailyMottoCard` / `DailyTabooCard` 미존재 (AC-11).
- [ ] T24 (ui) UI13: `testDailyMottoTabooShown_whenProvided` — `-mockTodayMottoTabooOn` 인자로 motto/taboo 주입(고정 문구 "오늘의 한마디 예시" / "금기 예시") 시 두 카드 노출 (AC-11).
- [ ] T25 (ui) UI14: `testDisclaimerAtBottom` — `DisclaimerText` 존재 (AC-12).
- [ ] T26 (ui) UI16: `testDynamicTypeXL_hapchungWrapsScoreVisible` — `.extraExtraExtraLarge` 적용 후 `HapchungRow_0_Score`("+12") fully visible (AC-14).
- [ ] T27 (ui) UI17: `testSajuMiniChartViewReused` — `SajuOriginChart`(SajuMiniChartView 내부 식별자) 존재 (AC-15).
