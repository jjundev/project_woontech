# WF3-06 — 오늘의 일진 상세 · Implement Plan v2

## 1. Goal

홈 Insights "일진" 카드 탭의 push 목적지인 `TodayDetailView`를 추가한다. 사주 원국 카드(`SajuMiniChartView` 재사용) + 오행 분포 + 십성 + 합충 카드를 mock provider 기반으로 렌더링하고, `HomeRoute.today` placeholder를 실제 화면으로 교체한다.

## 2. Affected files

### New

- `ios/Woontech/Features/Home/Detail/Today/TodayDetailProviding.swift`
  - `protocol TodayDetailProviding`, 데이터 모델(`SajuChartData`, `SipseongInfo`, `HapchungEvent`, `HapchungImpact`, `HapchungBranch`), `MockTodayDetailProvider`.
- `ios/Woontech/Features/Home/Detail/Today/TodayDetailView.swift`
  - 메인 `TodayDetailView` + 카드 sub-views (`SajuOriginCard`, `WuxingDistributionRow`, `SipseongCard`, `HapchungCard`, `HapchungRowView`, `MottoTabooCard`).
- `ios/WoontechTests/Home/TodayDetailViewTests.swift`
  - Provider 바인딩 / 분기 로직 단위 테스트.
- `ios/WoontechUITests/Home/TodayDetailUITests.swift`
  - Acceptance criterion 별 UI 테스트.

### Modified

- `ios/Woontech/Features/Home/HomeDependencies.swift`
  - `todayDetail: any TodayDetailProviding` 추가 + `MockTodayDetailProvider()` 기본값.
- `ios/Woontech/Features/Home/HomeDashboardView.swift`
  - `navigationDestination`의 `.today` 케이스에서 `TodayPlaceholderView()` → `TodayDetailView(provider: homeDeps.todayDetail)`로 교체.
- `ios/Woontech/Features/Home/HomeRouteDestinations.swift`
  - `TodayPlaceholderView`에 `@available(*, deprecated)` 마커 부착(다른 placeholder 패턴과 일관). 제거는 안전하지 않으므로 보존.

## 3. Data model / state changes

`TodayDetailProviding.swift` 안에 정의(상위 모듈 노출 최소화):

```swift
struct SajuChartData {
    let yearPillar: SajuPillar
    let monthPillar: SajuPillar
    let dayPillar: SajuPillar          // 일간(나)
    let hourPillar: SajuPillar
    let hourUnknown: Bool
    let dayMasterNature: String        // "강철" 등 — SajuMiniChartView 재사용 시 필요
    let investmentTags: String         // SajuMiniChartView 재사용 시 필요(없으면 "")
    let elementCounts: [WuxingElement: Int]  // 목·화·토·금·수 카운트(0~)
}

enum HapchungImpact { case positive, negative }

struct HapchungBranch {
    let hanja: String   // "申"
    let hangul: String  // "신금"
}

struct HapchungEvent: Identifiable {
    let id = UUID()
    let branch1: HapchungBranch
    let branch2: HapchungBranch
    let kind: String              // "육합", "월지충"
    let impact: HapchungImpact
    let score: Int                // ±값(부호 그대로 포함, 표시 시 +12 / −18)
    let note: String?             // 짧은 보조 설명(선택)
}

struct SipseongInfo {
    let name: String       // "편관"
    let hanja: String      // "偏官"
    let oneLiner: String
    let relation: String
    let examples: String
}

protocol TodayDetailProviding {
    var sajuChart: SajuChartData { get }
    var weakElement: WuxingElement? { get }   // 0개인 오행
    var sipseong: SipseongInfo { get }
    var hapchungEvents: [HapchungEvent] { get }
    var dailyMotto: String? { get }
    var dailyTaboo: String? { get }
}
```

기존 모델 재사용:
- `SajuPillar` (`Shared/SajuResultModel.swift`).
- `WuxingElement` (`Shared/SajuResultModel.swift`) — 스펙의 `WuXingElement`는 이 타입으로 매핑.
- `WuxingBar` — `SajuMiniChartView`에 전달 시 카운트를 `Double`로 정규화하여 사용.

`MockTodayDetailProvider` 기본값(스펙 §4):
- 일주: 庚午(경금), 일주표시 isDayPillar = true.
- 카운트: 목 1, 화 3, 토 1, 금 3, 수 0 → `weakElement = .water`.
- 십성: name "편관", hanja "偏官", oneLiner / relation / examples 와이어프레임 문구.
- hapchung: `[(申, 巳, 육합, +12, positive), (卯, 酉, 월지충, −18, negative)]`.
- `dailyMotto`, `dailyTaboo` 둘 다 nil 또는 짧은 예시(테스트 분기를 위해 nil 기본).

상태(`@State`)는 사용하지 않는다 — 본 화면은 read-only.

## 4. Implementation steps

각 단계는 컴파일·단위 테스트 가능 단위로 분리.

1. **Provider 추가**: `TodayDetailProviding.swift` 작성. 모델/프로토콜/Mock. 단위 테스트로 mock 기본값 검증.
2. **DI 배선**: `HomeDependencies`에 `todayDetail` 추가, `mock` 정적 인스턴스 유지.
3. **카드 1 — 사주 원국**:
   - `SajuOriginCard(provider:)` 생성.
   - 내부에서 `SajuMiniChartView`(기존)를 인스턴스화하여 4기둥 렌더(스펙 NFC: 재사용 우선).
   - 그 아래 `WuxingDistributionRow`: `WuxingElement.allCases` 5칸 고정, 각 칸 `한글(label)·한자(hanja: 木·火·土·金·水)·숫자` 출력. accessibilityIdentifier: `WuxingCell_<element>`.
   - `weakElement`가 nil이 아니면 경고 문구(`"\(hanja) 부족 → \(hanja) 기운의 날 주의"`) 렌더; nil이면 view에서 `EmptyView`.
4. **카드 2 — 십성**:
   - 좌측 56×56 검정 stamp(`name` bold + `hanja` caption, white text, RoundedRectangle ink fill).
   - 우측 VStack: `oneLiner`(headline bold) + `relation`(caption) + `examples`(caption2).
   - accessibilityIdentifiers: `SipseongStampName`, `SipseongStampHanja`, `SipseongOneLiner`, `SipseongRelation`, `SipseongExamples`.
5. **카드 3 — 합충**:
   - `hapchungEvents.isEmpty` → 카드 자체(헤더 포함)를 `if` 분기로 비표시(AC-8).
   - 헤더: 좌측 "오늘의 합충(合沖)" + 우측 범례 "합(+) · 충(−)".
   - `ForEach(provider.hapchungEvents) { row in HapchungRowView(event: row) }`.
   - row: 좌 branch1 박스 + 기호(`+`/`↔`) + 우 branch2 박스 + `kind` 배지 + Spacer + 우측 score 텍스트(부호 포함, `formattedScore` helper).
   - impact==positive: `RoundedRectangle.stroke(DesignTokens.line3, lineWidth: 1)`(실선).
   - impact==negative: `RoundedRectangle.stroke(DesignTokens.fireColor, style: StrokeStyle(lineWidth: 1, dash: [4,3]))`(점선) + 텍스트 `foregroundStyle(DesignTokens.fireColor)` 적용.
   - row 텍스트는 `.fixedSize(horizontal: false, vertical: true)`로 wrapping 보장(NFC Dynamic Type).
   - row accessibilityIdentifier: `HapchungRow_<index>`; accessibilityLabel: `"\(branch1.hanja) \(symbol) \(branch2.hanja), \(kind), \(score)점"` (NFC VoiceOver).
6. **카드 4 — 오늘의 한마디 / 금기 (옵션)**:
   - `if let motto = provider.dailyMotto { MottoCard(text: motto) }`, taboo 동일.
7. **푸터**: `DisclaimerView()` (재사용).
8. **NavBar**: `InvestingAttitudeDetailView`와 동일한 custom header 패턴(`HStack { Button(chevron.left) ; Text("오늘의 일진") ; Spacer() }`) 사용. `accessibilityIdentifier`는 `TodayDetailTitle` / `TodayDetailBackButton`.
9. **라우팅 교체**: `HomeDashboardView` `.today` 케이스를 `TodayDetailView(provider: homeDeps.todayDetail)`로 교체. 기존 hidden trigger button(`HomeNavPushToday`)은 그대로 — UI 테스트가 사용.
10. **#Preview**: `NavigationStack { TodayDetailView(provider: MockTodayDetailProvider()) }`.
11. **VoiceOver 순서**: 사주 원국 4기둥은 `SajuMiniChartView`가 `SajuPillar_year` → `_month` → `_day` → `_hour` 순서로 정의(이미 그 순서) — 자연 focus 순서로 충족.
12. **단위 테스트 + UI 테스트** 작성(아래 5·6).

## 5. Unit test plan (`TodayDetailViewTests`)

각 `XCTestCase`는 mock provider 기반으로 데이터 바인딩만 검증(SwiftUI 렌더는 UI 테스트로).

| # | 테스트 | 검증 대상 spec FR/AC |
|---|---|---|
| U1 | `testMockProviderDefaults_sajuChartPillars` — 4기둥 stem/branch가 와이어프레임 값(庚/午, 卯/酉 등) | FR sajuChart, AC-3 |
| U2 | `testMockProviderDefaults_elementCounts` — `[wood:1, fire:3, earth:1, metal:3, water:0]` | FR sajuChart, AC-4 |
| U3 | `testMockProviderDefaults_weakElementIsWater` — `weakElement == .water` | FR weakElement, AC-5 |
| U4 | `testMockProviderDefaults_sipseong` — name/hanja/oneLiner/relation/examples 모두 non-empty | FR sipseong, AC-6/7 |
| U5 | `testMockProviderDefaults_hapchungEvents` — 2개, 첫 +12 positive 申/巳, 둘째 −18 negative 卯/酉 | FR hapchungEvents, AC-9/10 |
| U6 | `testMockProviderDefaults_dailyMottoTabooNil` — 둘 다 nil(기본값) | AC-11 |
| U7 | `testCustomProvider_overridesAllFields` — 사용자 mock으로 모든 값 교체 후 동일하게 반영 | AC-13 |
| U8 | `testWeakElementNilWhenAllElementsPresent` — 카운트 모두 ≥1 인 mock에서 `weakElement == nil` | AC-5(부정) |
| U9 | `testHapchungEvents_emptyArrayCase` — empty array 허용, view 분기 트리거 가능 | AC-8 |
| U10 | `testFormattedScore_signing` — `+12` / `−18` 변환 helper(internal `static func formattedScore(_:Int)->String`) | AC-10 |
| U11 | `testWuxingHanjaMapping` — `WuxingElement → 한자`("木","火","土","金","水") 매핑 helper | AC-5 문구 |

## 6. UI test plan (`TodayDetailUITests`) — written, not executed by implementor

각 테스트는 `app.buttons["HomeNavPushToday"].tap()`으로 push 후 검증.

| # | 테스트 | 매핑 AC |
|---|---|---|
| UI1 | `testInsightsTodayCardTap_pushesTodayDetail` — `HomeInsightsCard_1` 탭 → `TodayDetailTitle` 노출 | AC-1 |
| UI2 | `testNavBarTitleAndBack` — title "오늘의 일진"; `TodayDetailBackButton` 탭 시 `HomeDashboardRoot` 복귀 | AC-2 |
| UI3 | `testSajuOriginRendersFourPillars` — `SajuPillar_year/_month/_day/_hour` 모두 존재 | AC-3, AC-15 |
| UI4 | `testWuxingDistributionFiveCellsOrder` — `WuxingCell_wood/_fire/_earth/_metal/_water` 모두 존재, 라벨에 한자+숫자 포함 | AC-4 |
| UI5 | `testWeakElementWarningRendered` — mock 기본값 → `WuxingWarningText` 라벨이 "水 부족" 포함 | AC-5 |
| UI6 | `testSipseongStamp` — `SipseongStampName.label == "편관"`, `SipseongStampHanja.label == "偏官"` | AC-6 |
| UI7 | `testSipseongRightSideThreeLines` — `SipseongOneLiner`, `SipseongRelation`, `SipseongExamples` 모두 존재 | AC-7 |
| UI8 | `testHapchungRowsRenderInOrder` — `HapchungRow_0`(申↔/+巳), `HapchungRow_1`(卯↔酉) 순서 | AC-8 |
| UI9 | `testHapchungCardHiddenWhenEmpty` — `app.launchArguments += ["-mockTodayHapchungEmpty"]` 으로 mock swap; `WoontechApp` 인자 파서가 해당 플래그 발견 시 `HomeDependencies(todayDetail: MockTodayDetailProvider(hapchungEvents: []))`로 교체. push 후 `HapchungSection` 비표시 검증 | AC-8 |
| UI10 | `testHapchungNegativeRowStyling` — `HapchungRow_1`의 score label이 "−18" 포함, 빨강 색 토큰은 visual; identifier `HapchungRow_1_NegativeStyle` 존재 여부로 검증 | AC-9 |
| UI11 | `testHapchungScoreFormatting` — score 양수 row label "+12" 포함, 음수 row "−18" 포함 | AC-10 |
| UI12 | `testDailyMottoTabooHidden_whenNil` — 기본 mock에서 `DailyMottoCard`, `DailyTabooCard` 미존재 | AC-11 |
| UI13 | `testDailyMottoTabooShown_whenProvided` — `-mockTodayMottoTabooOn` 인자로 motto/taboo 값 주입(고정 문구 "오늘의 한마디 예시" / "금기 예시") 시 두 카드 노출 | AC-11 |
| UI14 | `testDisclaimerAtBottom` — `DisclaimerText` 존재 | AC-12 |
| UI15 | (SKIP — 단위 테스트 U7가 AC-13의 "사용자 정의 mock 교체 시 모든 필드 반영"을 충족. spec AC-13에도 "단위 테스트" 명시.) | AC-13 → U7 |
| UI16 | `testDynamicTypeXL_hapchungWrapsScoreVisible` — `setPreferredContentSizeCategory(.extraExtraExtraLarge)` 후 `HapchungRow_0_Score`("+12") fully visible(`label.contains("…") == false`) | AC-14 |
| UI17 | `testSajuMiniChartViewReused` — `SajuOriginChart`(SajuMiniChartView 내부 identifier) 존재로 재사용 확인 | AC-15 |

UI 테스트가 mock swap을 필요로 하는 경우(empty hapchung, motto/taboo present) 구현 단계에서 `WoontechApp` 진입점의 **기존 `ProcessInfo.processInfo.arguments` 파싱 블록**(현재 `-mockHomeUnreadCount`, `-mockHeroScore` 등이 처리되는 곳)에 동일 패턴으로 분기 추가. 신규 키:
- `-mockTodayHapchungEmpty` → `MockTodayDetailProvider(hapchungEvents: [])`
- `-mockTodayMottoTabooOn` → `MockTodayDetailProvider(dailyMotto: "오늘의 한마디 예시", dailyTaboo: "금기 예시")`

`MockTodayDetailProvider`는 부분 override를 위해 모든 필드에 default 값을 가진 init을 제공한다. 이 외 사용자 정의 provider 교체(AC-13)는 단위 테스트 U7로 검증한다(`launchArguments` 경로 미사용). `app.launchEnvironment` 채널은 도입하지 않는다(코드베이스 컨벤션과 충돌).

## 7. Risks / open questions

1. **`SajuMiniChartView` API 적합성** — 기존 뷰는 `wuxing: [WuxingBar(value: Double)]`(0~1 normalized)와 `strongElements`/`supplementElements`/`investmentTags`/`dayMasterNature`를 모두 요구. 본 화면 스펙은 강함/보완/투자 태그가 없음.
   - 완화: `MockTodayDetailProvider`에서 카운트→Double로 정규화하고 `strongElements` = 카운트 ≥3, `supplementElements` = 카운트 0, `investmentTags`는 빈 문자열 또는 짧은 placeholder("—") 전달.
   - 위험: 미니바 + 하단 요약이 wireframe에서 요구하지 않은 영역을 노출. 시각적으로 어색할 경우 PR 설명에 메모(스펙 NFC가 명시).
   - 대안: 4기둥 그리드만 추출한 새로운 sub-view를 분리하지 않고, 한 번에 전체 SajuMiniChartView를 그대로 두고 그 아래 `WuxingDistributionRow`(한글·한자·숫자)를 **추가** 렌더 — AC-4(5칸 카운트 표시)는 이 추가 row로 충족.
2. **`weakElement` 한자 매핑 위치** — `WuxingElement`에 한자(`hanja`) 프로퍼티가 없음. 본 task 안에서 extension 추가(파일은 `TodayDetailProviding.swift`).
3. **합충 row 빨강 토큰** — `DesignTokens`에 별도 `danger`/`negative` 토큰 없음 → `fireColor`를 빨강으로 재사용. 디자인 검수 시 변경 가능.
4. **음수 부호 문자** — 스펙은 "−18"(U+2212 minus sign) 사용. 일반 hyphen(`-`)이 아님. helper에서 `score < 0 ? "−\(abs(score))" : "+\(score)"` 형태로 처리.
5. **NavBar pop 메커니즘** — `InvestingAttitudeDetailView`처럼 custom back button + `dismiss` 사용. `NavigationStack(path:)` 환경에서도 `dismiss`가 동작함을 기존 화면이 확인.
6. **Dynamic Type 합충 row score 잘림** — score 텍스트는 `.layoutPriority(1)` + branch box는 `.fixedSize`로 잘림 방지. 실패 시 `VStack`으로 폴백 레이아웃 고려(open).
7. **UI 테스트 mock 주입 범위** — 코드베이스 기존 컨벤션은 `launchArguments` + `-mock*` prefix(`WoontechApp.swift` 인자 파싱 블록). 본 task는 그 블록에 `-mockTodayHapchungEmpty`, `-mockTodayMottoTabooOn` 두 플래그만 추가하여 일관성을 유지한다. 별도 `launchEnvironment` 채널은 도입하지 않는다.
8. **Insights "일진" 카드 → today 라우팅** — 이미 `HomeDashboardView`의 `onTodayTap`에 `.today` push가 연결되어 있어 별도 변경 없음(AC-1 자동 충족).

PLAN_WRITTEN
