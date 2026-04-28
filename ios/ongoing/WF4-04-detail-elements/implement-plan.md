# implement-plan.md — WF4-04 오행 분포 상세 (v1)

---

## 1. Goal

`SajuTabView` NavigationStack의 `.elements` 라우트 목적지를 placeholder에서 **오행 분포 상세(`SajuElementsDetailView`)**로 교체한다. 사용자의 사주 8글자에 분포된 5행 비율을 막대 차트로 시각화하고, 부족 원소 보완 가이드를 카드로 제공하며, 독립 provider(`SajuElementsDetailProviding`) 를 통해 완전히 분리된 데이터를 주입받는다.

---

## 2. Affected Files

### New files

| 경로 | 설명 |
|------|------|
| `Woontech/Features/Saju/Detail/Elements/SajuElementsDetailView.swift` | 오행 분포 상세 화면 (메인 뷰 + 서브 컴포넌트) |
| `WoontechTests/Saju/SajuElementsDetailViewTests.swift` | 단위 테스트 |
| `WoontechUITests/Saju/SajuElementsDetailUITests.swift` | UI 테스트 |

### Modified files

| 경로 | 변경 내용 |
|------|-----------|
| `Woontech/Features/Saju/Providers/SajuElementsDetailProviding.swift` | 프로토콜 확장 + `ElementDistribution`·`ElementGuidance` 모델 추가 + `MockSajuElementsDetailProvider` 업데이트 |
| `Woontech/Features/Saju/SajuRouteDestinations.swift` | `.elements` 케이스 → `SajuElementsDetailView` 교체 |
| `Woontech/Features/Saju/SajuTabView.swift` | `sajuRouteDestination` 호출부에 `deps.elementsDetail` 전달 |
| `Woontech/Resources/ko.lproj/Localizable.strings` | 오행 분포 관련 로컬라이즈 키 추가 |
| `WoontechTests/Saju/SajuTabDependenciesTests.swift` | `summaryLine` → `summaryHeadline` 참조 수정 (breaking change 대응) |

---

## 3. Data Model / State Changes

### 3.1 `ElementDistribution` (신규 struct)

```
struct ElementDistribution {
    let symbol: String       // 한자 (예: "火")
    let koreanName: String   // 한국어명 (예: "화")
    let count: Int           // 해당 원소 글자 수 (0~max)
    let max: Int             // 기준 최대치 (스펙 기본값: 4)
    let note: String         // 표시 메모 (예: "왕성", "부족 ⚠")
    let isDeficient: Bool    // 부족 여부
}
```

### 3.2 `ElementGuidance` (신규 struct)

```
struct ElementGuidance {
    let targetSymbol: String  // 부족 원소 한자 (예: "水")
    let direction: String     // 방향 가이드 (예: "북쪽이 유리")
    let color: String         // 색상 가이드 (예: "검정·파랑 계열")
    let time: String          // 시간 가이드 (예: "저녁 23시 ~ 새벽 1시")
    let action: String        // 행동 가이드 (예: "계획·독서·수영")
}
```

### 3.3 `SajuElementsDetailProviding` 프로토콜 확장

기존 `summaryLine: String` 프로퍼티를 **제거**하고 다음으로 교체한다.

```
protocol SajuElementsDetailProviding {
    var summaryHeadline: String { get }           // 요약 한줄 (bold)
    var summaryBody: String { get }               // 요약 보조 본문 (muted)
    var elements: [ElementDistribution] { get }   // 고정 길이 5, 순서 [火木土金水]
    var guidance: ElementGuidance? { get }        // nil 이면 가이드 카드 숨김
}
```

### 3.4 `MockSajuElementsDetailProvider` 기본값

| 필드 | 기본값 |
|------|--------|
| `summaryHeadline` | `"火가 많고 水가 전혀 없는 사주"` |
| `summaryBody` | `"열정·추진력이 강하나 침착함·저축의 기운이 부족합니다."` |
| `elements[0]` (火) | count=3, max=4, note="왕성", isDeficient=false |
| `elements[1]` (木) | count=1, max=4, note="보통", isDeficient=false |
| `elements[2]` (土) | count=2, max=4, note="보통", isDeficient=false |
| `elements[3]` (金) | count=2, max=4, note="보통", isDeficient=false |
| `elements[4]` (水) | count=0, max=4, note="부족 ⚠", isDeficient=true |
| `guidance` | targetSymbol="水", direction="북쪽이 유리", color="검정·파랑 계열", time="저녁 23시 ~ 새벽 1시", action="계획·독서·수영" |

### 3.5 뷰 내부 상태

- 추가 `@State` 없음. 모든 표시 데이터는 `provider`(let 주입)에서 파생.
- 스크롤 위치 초기화: SwiftUI `ScrollView`는 진입 시 자동으로 최상단. 별도 처리 불필요.

### 3.6 정렬 로직

provider의 `elements` 배열을 symbol 값 기준으로 `[火, 木, 土, 金, 水]` 고정 순서로 재정렬하는 내부 헬퍼를 뷰 파일에 `private` 함수로 작성한다. 배열 길이가 5가 아니면 `preconditionFailure`를 호출한다(AC#7).

---

## 4. Implementation Steps

> 각 단계는 독립적으로 빌드·테스트 가능한 크기로 분리됨.

### Step 1 — `SajuElementsDetailProviding.swift` 확장

1. `ElementDistribution` 구조체 선언 (Equatable, 테스트 용이성).
2. `ElementGuidance` 구조체 선언 (Equatable).
3. `SajuElementsDetailProviding` 프로토콜에서 `summaryLine` 제거, 4개 프로퍼티 추가.
4. `MockSajuElementsDetailProvider`를 4개 필드(`summaryHeadline`, `summaryBody`, `elements`, `guidance`)로 재작성. `init` 기본값은 스펙 wireframe 텍스트 사용.
5. **빌드 확인**: `SajuTabDependenciesTests.swift`에서 `summaryLine` 참조 컴파일 에러 발생 → Step 2에서 수정.

### Step 2 — `SajuTabDependenciesTests.swift` 수정

1. `test_sajuTabDependencies_mock_compilesAndDefaults` 내 `deps.elementsDetail.summaryLine` → `deps.elementsDetail.summaryHeadline`으로 교체.
2. 스텁 `StubSajuElementsDetailProvider`에 `summaryHeadline`, `summaryBody`, `elements`, `guidance` 추가.
3. **빌드·테스트 통과** 확인.

### Step 3 — 로컬라이즈 키 추가 (`Localizable.strings`)

다음 키를 `/* Saju Elements Detail (WF4-04) */` 섹션 아래 추가:

```
"saju.elements.navTitle"              = "오행 분포";
"saju.elements.summary.sectionLabel"  = "오행 요약";
"saju.elements.dist.sectionLabel"     = "5행 분포";
"saju.elements.deficient.note"        = "부족";
"saju.elements.guidance.sectionLabel" = "보완 가이드";
"saju.elements.guidance.headerFormat" = "부족한 %@를 보완하려면";
"saju.elements.guidance.direction"    = "방향";
"saju.elements.guidance.color"        = "색상";
"saju.elements.guidance.time"         = "시간";
"saju.elements.guidance.action"       = "행동";
```

### Step 4 — `SajuElementsDetailView.swift` 신규 작성

파일 위치: `Woontech/Features/Saju/Detail/Elements/SajuElementsDetailView.swift`

#### 4-A. 메인 뷰 골격

```
struct SajuElementsDetailView: View {
    let provider: any SajuElementsDetailProviding
    // NavigationStack 자동 Back 버튼 사용 (iOS 17 toolbar API)

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                SajuElementsSummaryCard(...)
                SajuElementsDistributionCard(...)
                DisclaimerView()
                if let guidance = provider.guidance {
                    SajuElementsGuidanceCard(guidance: guidance)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(DesignTokens.bg)
        .navigationTitle(String(localized: "saju.elements.navTitle", defaultValue: "오행 분포"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("SajuElementsDetailView")
    }
}
```

- `.toolbar(.hidden)` 재정의: `SajuTabView`가 `SajuTabContentView`에 `.toolbar(.hidden, for: .navigationBar)`를 붙이지만, 상세 뷰는 NavigationStack 하위에서 `.toolbar(.visible)`로 오버라이드.
- Back 버튼은 NavigationStack 자동 제공 (iOS 17 표준). 별도 커스텀 Back 버튼 코드 불필요.

#### 4-B. `SajuElementsSummaryCard` (private struct)

- `VStack(alignment: .leading, spacing: 6)` 
- 섹션 라벨("오행 요약"): caption2, muted
- `summaryHeadline`: bold, 13pt, ink
- `summaryBody`: 10pt, muted
- 외곽: 패딩 12pt, border `DesignTokens.line3`, cornerRadius 6
- Accessibility: `.accessibilityElement(children: .ignore)`, `.accessibilityLabel("오행 요약, \(headline). \(body)")`
- `accessibilityIdentifier`: `"ElementsSummaryCard"`, headline 텍스트는 `"ElementsSummaryHeadline"`, body는 `"ElementsSummaryBody"`

#### 4-C. `SajuElementsDistributionCard` (private struct)

- 섹션 라벨("5행 분포"): caption2, muted
- 내부 정렬 헬퍼: `sortedElements(provider.elements)` → `[火, 木, 土, 金, 水]` 순서 (길이 != 5 이면 preconditionFailure)
- `ForEach`로 5개 행 → `ElementDistributionRow` 렌더
- `accessibilityIdentifier`: `"ElementsDistributionCard"`

#### 4-D. `ElementDistributionRow` (private struct)

- `HStack`: 좌측 (symbol bold 13pt + koreanName muted 10pt), 우측 (note · count/8 caption muted)
- 아래 막대 바 `GeometryReader`:
  - 회색 배경 Rectangle (height: max(8, 6) → 항상 min 8pt, 최소값 6pt 준수)
  - 채움 Rectangle: width = `geometry.size.width × CGFloat(item.count) / CGFloat(item.max)`
  - `isDeficient == true` → 채움 색 `DesignTokens.line2` (약한 톤); 아니면 해당 원소 wuxing 색상 (`DesignTokens.fireColor` 등)
- Accessibility (각 행):
  - `.accessibilityElement(children: .ignore)`
  - `isDeficient` 행: label = `"부족, \(koreanName) \(symbol), \(note), \(count)점 8점 만점 중"`, trait `.isSelected`(또는 별도 trait으로 부족 강조)
  - 일반 행: label = `"\(koreanName) \(symbol), \(note), \(count)점 8점 만점 중"`
  - `accessibilityIdentifier`: `"ElementRow_\(symbol)"`

#### 4-E. `SajuElementsGuidanceCard` (private struct)

- 헤더: `String(format: "부족한 %@를 보완하려면", guidance.targetSymbol)` — bold 13pt
- 4개 bullet row (방향/색상/시간/행동): `label: value` 형태 (label: muted caption, value: ink body)
- Accessibility 각 bullet: label = `"\(label) 보완: \(value)"`
- `accessibilityIdentifier`: `"ElementsGuidanceCard"`, 헤더 `"GuidanceHeader"`, 각 bullet `"GuidanceBullet_direction"` 등

### Step 5 — `SajuRouteDestinations.swift` + `SajuTabView.swift` 수정

**방법**: `sajuRouteDestination(for:)` 자유 함수의 시그니처를 `sajuRouteDestination(for:deps:)` 로 변경하고, `SajuTabView` 호출부에서 `deps`를 전달.

```swift
// SajuRouteDestinations.swift
@ViewBuilder
func sajuRouteDestination(for route: SajuRoute, deps: SajuTabDependencies) -> some View {
    switch route {
    case .elements:
        SajuElementsDetailView(provider: deps.elementsDetail)
    case .tenGods:
        SajuPlaceholderDestinationView(routeKey: "tenGods")
    // … 나머지 케이스 unchanged …
    }
}
```

```swift
// SajuTabView.swift — navigationDestination 클로저
.navigationDestination(for: SajuRoute.self) { route in
    sajuRouteDestination(for: route, deps: deps)
}
```

### Step 6 — 전체 빌드 및 기존 테스트 확인

- `SajuTabDependenciesTests` 전체 pass.
- `SajuRouteTests` pass (`.elements` case hashability 변경 없음).
- 기타 기존 Saju 테스트 pass.

### Step 7 — `SajuElementsDetailViewTests.swift` 작성

(상세 내용은 §5 참조)

### Step 8 — `SajuElementsDetailUITests.swift` 작성

(상세 내용은 §6 참조)

---

## 5. Unit Test Plan

파일: `WoontechTests/Saju/SajuElementsDetailViewTests.swift`

### Group A — 프로토콜 분리 (AC#12)

| 테스트 이름 | 검증 내용 |
|------------|-----------|
| `test_protocolSeparation_elementsNotCategories` | `SajuElementsDetailProviding`에 `SajuCategoriesProviding` 멤버가 없음(컴파일 타임) — Mock을 각각 상호 대입 시도 시 컴파일 에러. 코멘트로 설명. |

### Group B — Mock provider 기본값 (AC#3, AC#13)

| 테스트 이름 | 검증 내용 |
|------------|-----------|
| `test_mockProvider_summaryHeadlineDefault` | `summaryHeadline == "火가 많고 水가 전혀 없는 사주"` |
| `test_mockProvider_summaryBodyDefault` | `summaryBody == "열정·추진력이 강하나 침착함·저축의 기운이 부족합니다."` |
| `test_mockProvider_elementsCount5` | `elements.count == 5` |
| `test_mockProvider_elementsOrder` | `[0].symbol=="火", [1].symbol=="木", [2].symbol=="土", [3].symbol=="金", [4].symbol=="水"` |
| `test_mockProvider_guidanceNotNil` | `guidance != nil` |
| `test_mockProvider_guidanceTargetSymbol` | `guidance?.targetSymbol == "水"` |
| `test_mockProvider_customInit_reflectsAllFields` | 임의 값으로 init → 모든 필드 반영 (AC#13) |

### Group C — 분포 비율 계산 (AC#5)

| 테스트 이름 | 검증 내용 |
|------------|-----------|
| `test_barFillRatio_count3_max4_is75Percent` | `CGFloat(3)/CGFloat(4) == 0.75` |
| `test_barFillRatio_count0_max4_is0Percent` | `CGFloat(0)/CGFloat(4) == 0.0` |
| `test_barFillRatio_count4_max4_is100Percent` | `CGFloat(4)/CGFloat(4) == 1.0` |

### Group D — 부족 원소 표시 (AC#6)

| 테스트 이름 | 검증 내용 |
|------------|-----------|
| `test_deficientElement_isDeficientTrue` | mock 水 element의 `isDeficient == true` |
| `test_deficientElement_noteContains부족` | mock 水 element의 `note` 에 "부족" 포함 |
| `test_nonDeficient_element_isDeficientFalse` | mock 火 element의 `isDeficient == false` |

### Group E — guidance nil/non-nil (AC#8, AC#9)

| 테스트 이름 | 검증 내용 |
|------------|-----------|
| `test_guidanceNonNil_cardRendered` | guidance != nil mock → `SajuElementsDetailView` 생성 성공, view 구조 내 guidance card 존재 |
| `test_guidanceNil_cardAbsent` | guidance == nil mock → guidance card 없음 |
| `test_guidanceHeader_containsTargetSymbol` | guidance.targetSymbol이 헤더 텍스트에 포함됨 |

### Group F — guidance bullet 매핑 (AC#10)

| 테스트 이름 | 검증 내용 |
|------------|-----------|
| `test_guidanceBullets_directionValue` | `guidance.direction` 값 반영 확인 |
| `test_guidanceBullets_colorValue` | `guidance.color` 값 반영 확인 |
| `test_guidanceBullets_timeValue` | `guidance.time` 값 반영 확인 |
| `test_guidanceBullets_actionValue` | `guidance.action` 값 반영 확인 |

### Group G — precondition (AC#7)

| 테스트 이름 | 검증 내용 |
|------------|-----------|
| `test_sortedElements_length5_succeeds` | 5개 배열 → 결과 5개, 예외 없음 |
| `test_sortedElements_lengthNot5_preconditionFails` | 4개/6개 배열 → `preconditionFailure` (XCTAssertTrue(try) 또는 `expectPreconditionFailure` 패턴) |

> `preconditionFailure` 테스트는 `XCTExpectFailure` 또는 별도 헬퍼로 처리 (Swift에서 `precondition`은 debug 빌드에서만 트랩 가능).

### Group H — SajuTabDependencies 통합 (AC#12)

| 테스트 이름 | 검증 내용 |
|------------|-----------|
| `test_sajuTabDeps_elementsDetailReplaceable` | `SajuTabDependencies(elementsDetail: StubElementsDetailProvider())` 후 `summaryHeadline` 반영 |

---

## 6. UI Test Plan

파일: `WoontechUITests/Saju/SajuElementsDetailUITests.swift`

> 모든 테스트는 `-openSajuTab` launch argument로 시작 → `app.buttons["SajuNavPush_elements"].tap()` 으로 화면 진입.

### Navigation (AC#1, AC#2)

| 테스트 이름 | 검증 내용 |
|------------|-----------|
| `testNavPush_elements_showsDetailView` | `SajuNavPush_elements` 탭 → `app.otherElements["SajuElementsDetailView"]` 존재 |
| `testNavBarTitle_isOhaengBunpo` | NavBar 타이틀 텍스트 = "오행 분포" |
| `testBackButton_popsToSajuHome` | 상세 진입 후 Back 탭 → `SajuTabRoot` visible |

### Summary card (AC#3)

| 테스트 이름 | 검증 내용 |
|------------|-----------|
| `testSummaryCard_headlineVisible` | `app.staticTexts["ElementsSummaryHeadline"]` 존재, label 비어있지 않음 |
| `testSummaryCard_bodyVisible` | `app.staticTexts["ElementsSummaryBody"]` 존재 |
| `testSummaryCard_headlineEqualsProviderValue` | label == mock summaryHeadline 기본값 |

### 5-element distribution (AC#4, AC#5, AC#6)

| 테스트 이름 | 검증 내용 |
|------------|-----------|
| `testDistribution_fiveRowsExist` | `ElementRow_火`, `_木`, `_土`, `_金`, `_水` 모두 존재 |
| `testDistribution_orderIsFireWoodEarthMetalWater` | 다섯 행의 화면 Y좌표 순서 확인 |
| `testDistribution_deficientRow_水_noteContains부족` | 水 행의 접근성 레이블에 "부족" 포함 |

### Disclaimer (AC#11)

| 테스트 이름 | 검증 내용 |
|------------|-----------|
| `testDisclaimer_exists` | `app.staticTexts["DisclaimerText"]` 존재 |
| `testDisclaimer_text_matchesWF1WF2WF3` | 레이블에 "학습·참고용" 포함 |

### Guidance card (AC#8, AC#9, AC#10)

| 테스트 이름 | 검증 내용 |
|------------|-----------|
| `testGuidanceCard_visibleWithDefaultMock` | `"ElementsGuidanceCard"` 존재 |
| `testGuidanceCard_header_contains水` | `"GuidanceHeader"` 레이블에 "水" 포함 |
| `testGuidanceCard_fourBullets_exist` | `"GuidanceBullet_direction"` ~ `"GuidanceBullet_action"` 모두 존재 |
| `testGuidanceCard_hiddenWhenGuidanceNil` | guidance=nil 전용 launch argument로 실행 시 `"ElementsGuidanceCard"` 미존재 (추후 launch arg `-sajuElementsNoGuidance` 추가 필요) |

### VoiceOver focus order (AC#14)

| 테스트 이름 | 검증 내용 |
|------------|-----------|
| `testAccessibility_elementsAfterSummary` | `ElementsSummaryCard`의 Y 좌표 < `ElementRow_火` < `DisclaimerText` (레이아웃 순서 프록시) |

### Dynamic Type (AC#15)

| 테스트 이름 | 검증 내용 |
|------------|-----------|
| `testDynamicTypeXL_guidanceBulletVisible` | contentSizeCategory `.extraExtraExtraLarge` → `"GuidanceBullet_direction"` 존재, label 에 "…" 없음 |
| `testDynamicTypeXL_distributionRowVisible` | XL → `ElementRow_火` 존재 |

---

## 7. Risks / Open Questions

### R1 — 레이아웃 순서 스펙 불일치 (⚠ 주요 위험)

**문제**: 기능 요구사항 레이아웃 번호는 `1-요약 → 2-분포 → 3-Disclaimer → 4-가이드` 순이나, 인수 조건 AC#8은 "가이드 카드가 5행 분포 카드와 Disclaimer **사이에** 렌더"된다고 명시. 두 진술이 상충한다.

반면 AC#14(VoiceOver 순서)는 `… → Disclaimer → 가이드(있을 때)`로 기술하여 레이아웃 번호 순서(Disclaimer가 가이드 앞)를 지지한다.

**권고**: 구현 착수 전 스펙 작성자에게 확인. 확인 전까지 **레이아웃 번호 + AC#14** 기준(summary → elements → Disclaimer → guidance)으로 구현하고, AC#8 검증 테스트에 주석으로 모순 사항을 기재.

### R2 — `toolbar(.hidden)` 오버라이드 동작

`SajuTabView`가 `SajuTabContentView`에 `.toolbar(.hidden, for: .navigationBar)`를 적용하므로 네비게이션 목적지도 같은 설정을 상속받을 수 있다. 상세 뷰에서 `.toolbar(.visible, for: .navigationBar)` 재선언이 제대로 적용되는지 시뮬레이터에서 반드시 확인 필요.

### R3 — `sajuRouteDestination` 시그니처 변경 영향

`sajuRouteDestination(for:)`를 `(for:deps:)`로 변경하면 기존 `SajuRouteTests.swift`등에서 컴파일 에러가 날 수 있다. 테스트 파일에서 해당 함수를 직접 호출하는 경우 수정 필요. 미리 그렙 후 확인.

### R4 — `preconditionFailure` 테스트 가능성

Swift의 `precondition`은 릴리즈 빌드에서 최적화 제거될 수 있고, 테스트 타겟에서 트랩을 캐치하기 어렵다. `XCTExpectFailure` 또는 사전 조건을 테스트 가능한 `guard + return` 패턴으로 교체하는 대안 검토 필요. AC#7은 "precondition 실패"라고 명시하므로 `preconditionFailure` 사용을 유지하되, 테스트는 정상 경로(길이 5)만 단위테스트로 검증하고 비정상 경로(길이 != 5)는 코드 리뷰 + 주석으로 갈음 가능.

### R5 — 원소별 wuxing 색상 매핑

`DesignTokens`에는 `fireColor`, `woodColor`, `earthColor`, `metalColor`, `waterColor`가 이미 정의되어 있다. 상세 뷰에서 symbol → 색상을 switch로 매핑할 때 오타/누락 방지를 위해 `ElementDistribution`에 `wuxingColor` computed property를 추가하거나 별도 매핑 함수를 정의하는 것 권장.

### R6 — guidance nil 분기 UI 테스트 진입 경로

`guidance == nil` UI 테스트(AC#9)는 별도 mock 데이터 주입 방법이 필요하다. 현재 앱은 process argument 기반으로 provider를 교체하지 않는다. 구현 시 `-sajuElementsNoGuidance` launch argument 처리를 `SajuTabDependencies` 또는 AppDelegate에 추가하거나, 해당 UI 테스트를 "주석 처리 후 단위 테스트로만 검증" 방식으로 처리하는 결정을 구현자가 내려야 한다.

### R7 — `summaryLine` breaking change

`SajuTabDependenciesTests`의 T4 테스트(`test_sajuTabDependencies_mock_compilesAndDefaults`)가 `summaryLine`을 직접 참조. Step 2에서 수정 필요. 수정 누락 시 전체 테스트 스위트 빌드 실패.
