# implement-plan.md — WF4-02 사주 탭 Above-the-Fold (v2)

---

## 1. Goal

사주 탭(`SajuTabView`) 컨텐츠 슬롯 최상단에, WF4-01에서 선언된 `UserSajuOriginProviding` · `SajuCategoriesProviding`의 mock 데이터를 바인딩하여 **내 원국 4주 카드(Block A)** 와 **"내 사주 자세히" 5-카테고리 카드 섹션(Block B)** 을 구현한다. 현재의 "준비중" placeholder를 실제 컨텐츠 View로 교체한다.

---

## 2. Affected Files

| 경로 | 상태 |
|---|---|
| `Woontech/Features/Saju/AboveFold/SajuPillarCellView.swift` | **NEW** |
| `Woontech/Features/Saju/AboveFold/SajuOriginCardView.swift` | **NEW** |
| `Woontech/Features/Saju/AboveFold/SajuCategoryCardView.swift` | **NEW** |
| `Woontech/Features/Saju/AboveFold/SajuCategoriesSection.swift` | **NEW** |
| `Woontech/Features/Saju/SajuTabContentView.swift` | **NEW** |
| `Woontech/Features/Saju/SajuTabView.swift` | **MODIFIED** |
| `Woontech/Shared/DesignTokens.swift` | **MODIFIED** |
| `Woontech/Features/Saju/UserSajuOriginProviding.swift` | **MODIFIED** (mock data — see Step 0) |
| `Woontech/Features/Saju/SajuCategoriesProviding.swift` | **MODIFIED** (mock data — see Step 0) |
| `WoontechTests/Saju/SajuAboveFoldTests.swift` | **NEW** |
| `WoontechUITests/Saju/SajuAboveFoldUITests.swift` | **NEW** |

> `SajuTabContentPlaceholderView.swift` は削除しない — WF4-01 UI 테스트
> (`SajuTabContentPlaceholderText`, `SajuTabContentPlaceholder` 식별자)가 여전히
> 참조하는지 확인 필요(아래 7. 리스크 참조). 삭제 시 T17 테스트가 깨진다.

---

## 3. Data Model / State Changes

### 3-1. 새 DesignTokens (DesignTokens.swift 추가)

```
DesignTokens.dayMasterHighlight   // 일간 천간 셀 강조 배경 (예: gray2 #D6D6D6)
DesignTokens.dayMasterLineBg      // 일간 한줄 박스 배경 (예: gray  #F2F2F2)
```

기존 `DesignTokens.gray` / `DesignTokens.gray2` 재활용 또는 별칭으로 이름 부여.

### 3-2. 기존 모델 (수정 없음)

| 타입 | 파일 | 역할 |
|---|---|---|
| `Pillar` / `Pillar.Position` | `UserSajuOriginProviding.swift` | 기둥 데이터 |
| `UserSajuOriginProviding` | 동일 | Block A 데이터 소스 |
| `MockUserSajuOriginProvider` | 동일 | 기본 mock (時庚申/日丙午/月辛卯/年庚午) |
| `SajuCategorySummary` / `.Kind` | `SajuCategoriesProviding.swift` | 카테고리 데이터 |
| `SajuCategoriesProviding` | 동일 | Block B 데이터 소스 |
| `MockSajuCategoriesProvider` | 동일 | 5슬롯 기본 mock |
| `SajuTabDependencies` | `SajuTabDependencies.swift` | DI 컨테이너 (변경 없음) |
| `SajuRoute` | `SajuRoute.swift` | 내비게이션 (변경 없음) |

### 3-3. 상태 흐름

```
SajuTabView
  @State navigationPath: [SajuRoute]     ← 기존 유지
  @EnvironmentObject deps: SajuTabDependencies

  └─ SajuTabContentView(
       originProvider: deps.userSajuOrigin,
       categoriesProvider: deps.categories,
       onNavigate: { route in navigationPath.append(route) }
     )
       ├─ SajuOriginCardView(provider: originProvider)
       └─ SajuCategoriesSection(
            provider: categoriesProvider,
            onNavigate: onNavigate
          )
```

`SajuTabContentView`는 `navigationPath` 바인딩 대신 `onNavigate` 클로저를 받아
레이어 분리를 유지한다.

---

## 4. Implementation Steps

### Step 0 — Mock 공급자 데이터 확인 및 구현

**왜 필요한가**: 스펙에 따르면 이 슬라이스는 WF4-01에서 시그니처만 선언된
`UserSajuOriginProviding`·`SajuCategoriesProviding`의 **mock 구현을 완성**한다.
WF4-01이 스텁/빈 mock만 남겼을 경우 TA-02~TA-07, TA-15/TA-16 등 단위 테스트가 실패하므로,
구현 전 반드시 아래 값이 실제 코드에 존재하는지 확인하고 없으면 추가한다.

#### `MockUserSajuOriginProvider` (`UserSajuOriginProviding.swift`)

`pillars` 기본값이 정확히 아래 4개여야 한다:

```swift
Pillar(position: .hour,  heavenlyStem: "庚", earthlyBranch: "申"),
Pillar(position: .day,   heavenlyStem: "丙", earthlyBranch: "午"),
Pillar(position: .month, heavenlyStem: "辛", earthlyBranch: "卯"),
Pillar(position: .year,  heavenlyStem: "庚", earthlyBranch: "午"),
```

`dayMasterLine` 기본값:

```swift
"일간 丙火 · 양의 불 — 따뜻함, 표현력, 리더십"
```

#### `MockSajuCategoriesProvider` (`SajuCategoriesProviding.swift`)

`categories` 기본값이 정확히 아래 5개여야 한다:

```swift
SajuCategorySummary(kind: .elements, summary: "火 3 · 金 2 · 木 1 · 水 0 · 土 2", badge: "부족: 水"),
SajuCategorySummary(kind: .tenGods,  summary: "비견·식신·정재 강함",              badge: nil),
SajuCategorySummary(kind: .daewoon,  summary: "현재 丁巳 대운 (32~41)",           badge: "전환기"),
SajuCategorySummary(kind: .hapchung, summary: "일지-시지 合, 월지 沖",             badge: nil),
SajuCategorySummary(kind: .yongsin,  summary: "水 용신, 金 희신",                 badge: nil),
```

값이 이미 올바르면 아무것도 수정하지 않아도 된다(수정 없음). 값이 스텁이면 위 값으로 교체한다.

---

### Step 1 — DesignTokens 토큰 추가

`Woontech/Shared/DesignTokens.swift`에 다음 두 정적 프로퍼티를 추가한다.

```swift
// MARK: - 사주 원국 카드 토큰
static let dayMasterHighlight = Color(red: 0xD6/255, green: 0xD6/255, blue: 0xD6/255) // gray2 재사용
static let dayMasterLineBg    = Color(red: 0xF2/255, green: 0xF2/255, blue: 0xF2/255) // gray 재사용
```

> 배경 구분이 필요하므로 `dayMasterHighlight`(`gray2`)와 일반 카드 배경(`bg`/white)이
> 시각적으로 구별되어야 한다. 기존 `gray2 = #D6D6D6`이 적합.

---

### Step 2 — `SajuPillarCellView` 작성

파일: `Woontech/Features/Saju/AboveFold/SajuPillarCellView.swift`

**역할**: 기둥 1개 셀 렌더.

**입력 프로퍼티**:
- `pillar: Pillar`
- `columnLabel: String`  — 한자 레이블 (時/日/月/年)
- `isDayMaster: Bool`    — 일간 여부 (강조 배경 적용)

**레이아웃**:
```
VStack(spacing: 4) {
    Text(columnLabel)  // 기둥 이름, 10pt muted
    RoundedRectangle 또는 ZStack {
        Text(pillar.heavenlyStem)  // 천간 한자 14pt
    }
    .background(isDayMaster ? DesignTokens.dayMasterHighlight : DesignTokens.bg)
    .cornerRadius(4)
    RoundedRectangle 또는 ZStack {
        Text(pillar.earthlyBranch) // 지지 한자 14pt
    }
    .background(DesignTokens.gray)
    .cornerRadius(4)
}
```

**Accessibility**:
- 셀 전체에 `.accessibilityLabel("{columnLabel}, 천간 \(pillar.heavenlyStem), 지지 \(pillar.earthlyBranch)")`
- `isDayMaster` 시 `.accessibilityAddTraits(.isHeader)` (또는 커스텀 트레잇 "강조" 마킹 — `.isHeader`가 가장 근접한 표준 트레잇)
- `.accessibilityElement(children: .ignore)`로 내부 Text 개별 읽기 방지
- `accessibilityIdentifier("SajuPillarCell_\(pillar.position.rawValue)")`

---

### Step 3 — `SajuOriginCardView` 작성

파일: `Woontech/Features/Saju/AboveFold/SajuOriginCardView.swift`

**역할**: Block A 전체 카드.

**입력**:
- `provider: any UserSajuOriginProviding`
- `onViewAll: () -> Void`  — "전체 보기 ›" 탭 콜백 (no-op 전달)

**레이아웃**:
```
VStack(spacing: 8) {
    // 헤더 행
    HStack {
        Text("내 사주 원국")  // 12pt muted
            .accessibilityIdentifier("SajuOriginCardHeaderLabel")
        Spacer()
        Button("전체 보기 ›") { onViewAll() }
            .font(.system(size: 12))
            .foregroundStyle(DesignTokens.muted)
            .accessibilityHint("준비중")
            .accessibilityIdentifier("SajuOriginCardViewAllButton")
    }

    // 4-column grid
    HStack(spacing: 8) {
        ForEach(displayOrder, id: \.self) { position in
            SajuPillarCellView(
                pillar: pillarMap[position]!,
                columnLabel: label(for: position),
                isDayMaster: position == .day
            )
            .frame(maxWidth: .infinity)
        }
    }

    // 일간 한줄 박스
    Text(provider.dayMasterLine)
        .font(.system(size: 13))
        .foregroundStyle(DesignTokens.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(DesignTokens.dayMasterLineBg)
        .cornerRadius(6)
        .fixedSize(horizontal: false, vertical: true) // Dynamic Type wrapping
        .accessibilityIdentifier("SajuDayMasterLine")
}
.padding(16)
.background(DesignTokens.bg)
.accessibilityIdentifier("SajuOriginCard")
```

**pillar 정렬 로직**:
```swift
let displayOrder: [Pillar.Position] = [.hour, .day, .month, .year]

// body 진입 시 precondition
precondition(provider.pillars.count == 4,
    "UserSajuOriginProviding must supply exactly 4 pillars (hour/day/month/year)")

let pillarMap: [Pillar.Position: Pillar] = Dictionary(
    uniqueKeysWithValues: provider.pillars.map { ($0.position, $0) }
)
```

**column label 함수**:
```swift
func label(for position: Pillar.Position) -> String {
    switch position {
    case .hour:  return "時"
    case .day:   return "日"
    case .month: return "月"
    case .year:  return "年"
    }
}
```

---

### Step 4 — `SajuCategoryCardView` 작성

파일: `Woontech/Features/Saju/AboveFold/SajuCategoryCardView.swift`

**역할**: 카테고리 카드 1개.

**입력**:
- `summary: SajuCategorySummary?` — nil이면 "데이터 없음" placeholder 렌더
- `kind: SajuCategorySummary.Kind` — 식별자용
- `onTap: () -> Void`

**레이아웃** (summary 있을 때):
```
Button(action: onTap) {
    HStack(alignment: .center) {
        // 좌측
        VStack(alignment: .leading, spacing: 4) {
            Text(summary.title)  // 14pt bold ink
            Text(summary.summary) // 13pt muted, multiline
                .fixedSize(horizontal: false, vertical: true)
            if let badge = summary.badge {
                Text(badge)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(DesignTokens.gray2)
                    .cornerRadius(10)
                    .accessibilityIdentifier("SajuCategoryBadge_\(kind.rawValue)")
            }
        }
        Spacer()
        // 우측
        VStack(alignment: .trailing, spacing: 4) {
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundStyle(DesignTokens.muted)
            Text("근거 보기")
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.muted)
                .underline()
                .accessibilityIdentifier("SajuCategoryEvidence_\(kind.rawValue)")
        }
    }
    .padding(.horizontal, 16).padding(.vertical, 12)
    .frame(minHeight: 44)    // hit target 보장
    .contentShape(Rectangle())
}
.buttonStyle(.plain)
.background(DesignTokens.bg)
.accessibilityLabel("\(summary.title), \(summary.summary)\(summary.badge.map { ", \($0) 표시" } ?? "")")
.accessibilityIdentifier("SajuCategoryCard_\(kind.rawValue)")
```

**placeholder (summary == nil)**:
```
HStack {
    Text("데이터 없음")
        .font(.system(size: 13))
        .foregroundStyle(DesignTokens.muted)
    Spacer()
}
.padding(.horizontal, 16).padding(.vertical, 12)
.frame(minHeight: 44)
.background(DesignTokens.bg)
.accessibilityIdentifier("SajuCategoryCard_\(kind.rawValue)")
```

---

### Step 5 — `SajuCategoriesSection` 작성

파일: `Woontech/Features/Saju/AboveFold/SajuCategoriesSection.swift`

**역할**: Block B 전체 (헤더 + 5 카드 리스트).

**입력**:
- `provider: any SajuCategoriesProviding`
- `onNavigate: (SajuRoute) -> Void`

**5슬롯 고정 순서**:
```swift
let displayOrder: [SajuCategorySummary.Kind] = [.elements, .tenGods, .daewoon, .hapchung, .yongsin]
```

**카테고리 → 라우트 매핑**:
```swift
func route(for kind: SajuCategorySummary.Kind) -> SajuRoute {
    switch kind {
    case .elements: return .elements
    case .tenGods:  return .tenGods
    case .daewoon:  return .daewoonPlaceholder
    case .hapchung: return .hapchungPlaceholder
    case .yongsin:  return .yongsinPlaceholder
    }
}
```

**레이아웃**:
```
VStack(alignment: .leading, spacing: 0) {
    Text("내 사주 자세히")
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(DesignTokens.ink)
        .padding(.horizontal, 16).padding(.bottom, 8)
        .accessibilityIdentifier("SajuDetailSectionHeader")

    VStack(spacing: 8) {
        ForEach(displayOrder, id: \.self) { kind in
            let summary = provider.categories.first(where: { $0.kind == kind })
            SajuCategoryCardView(
                summary: summary,
                kind: kind,
                onTap: { onNavigate(route(for: kind)) }
            )
        }
    }
    .padding(.horizontal, 16)
}
```

---

### Step 6 — `SajuTabContentView` 작성

파일: `Woontech/Features/Saju/SajuTabContentView.swift`

**역할**: `SajuTabView`의 NavigationStack 내부 root 뷰. Block A + Block B를 `ScrollView` 안에 배치하고, WF4-01의 `SajuTabContentPlaceholderView`를 대체한다.

**입력**:
- `originProvider: any UserSajuOriginProviding`
- `categoriesProvider: any SajuCategoriesProviding`
- `onNavigate: (SajuRoute) -> Void`

**레이아웃**:
```
ScrollView {
    VStack(spacing: 16) {
        SajuOriginCardView(
            provider: originProvider,
            onViewAll: { /* no-op */ }
        )
        SajuCategoriesSection(
            provider: categoriesProvider,
            onNavigate: onNavigate
        )
        Spacer(minLength: 32)  // WF4-03 섹션 공간 예약
    }
    .padding(.horizontal, 0) // 내부 컴포넌트가 각자 16pt 적용
    .padding(.top, 16)
}
.accessibilityElement(children: .contain)
.accessibilityIdentifier("SajuTabContent")
```

---

### Step 7 — `SajuTabView` 수정

`Woontech/Features/Saju/SajuTabView.swift`에서:

```swift
// BEFORE
NavigationStack(path: $navigationPath) {
    SajuTabContentPlaceholderView()
        .toolbar(.hidden, for: .navigationBar)
        ...
}

// AFTER
NavigationStack(path: $navigationPath) {
    SajuTabContentView(
        originProvider: deps.userSajuOrigin,
        categoriesProvider: deps.categories,
        onNavigate: { route in navigationPath.append(route) }
    )
    .toolbar(.hidden, for: .navigationBar)
    .navigationDestination(for: SajuRoute.self) { route in
        sajuRouteDestination(for: route)
    }
}
```

> `SajuTabContentPlaceholderView`는 코드베이스에 남겨 두되, `SajuTabView`에서만
> 참조를 교체한다. WF4-01 UI 테스트(T17)가 `SajuTabContentPlaceholderText` 식별자를
> 찾으므로, 그 테스트를 **삭제 또는 skip** 처리해야 한다(아래 7. 리스크 참조).

---

### Step 8 — 접근성 식별자 체크리스트

구현 시 아래 `accessibilityIdentifier` 값을 정확히 설정한다(UI 테스트가 이 값을 사용).

| 뷰 | identifier |
|---|---|
| `SajuTabContentView` 최외곽 ScrollView | `"SajuTabContent"` |
| `SajuOriginCardView` | `"SajuOriginCard"` |
| "내 사주 원국" 라벨 | `"SajuOriginCardHeaderLabel"` |
| "전체 보기 ›" 버튼 | `"SajuOriginCardViewAllButton"` |
| 기둥 셀 (position.rawValue = hour/day/month/year) | `"SajuPillarCell_{position}"` |
| 일간 한줄 박스 | `"SajuDayMasterLine"` |
| "내 사주 자세히" 헤더 | `"SajuDetailSectionHeader"` |
| 카테고리 카드 (kind.rawValue = elements/tenGods/daewoon/hapchung/yongsin) | `"SajuCategoryCard_{kind}"` |
| 카테고리 badge | `"SajuCategoryBadge_{kind}"` |
| "근거 보기" | `"SajuCategoryEvidence_{kind}"` |

---

## 5. Unit Test Plan

파일: `WoontechTests/Saju/SajuAboveFoldTests.swift`

각 테스트는 `@testable import Woontech` 사용. SwiftUI View 렌더링은 단위 테스트에서
직접 불가하므로 로직/모델 레이어를 테스트한다.

| ID | 테스트명 | 검증 내용 | AC |
|---|---|---|---|
| TA-01 | `test_pillarDisplayOrder_isFixed_時日月年` | `displayOrder` 배열이 `[.hour, .day, .month, .year]`인지 검증 | 2 |
| TA-02 | `test_mockOriginProvider_defaultPillars_containsDay丙午` | `MockUserSajuOriginProvider.defaultPillars`에서 `.day` 기둥의 `heavenlyStem == "丙"`, `earthlyBranch == "午"` | 3 |
| TA-03 | `test_mockOriginProvider_defaultPillars_containsHour庚申` | `.hour` 기둥: `heavenlyStem == "庚"`, `earthlyBranch == "申"` | 3 |
| TA-04 | `test_mockOriginProvider_defaultPillars_containsMonth辛卯` | `.month` 기둥: `heavenlyStem == "辛"`, `earthlyBranch == "卯"` | 3 |
| TA-05 | `test_mockOriginProvider_defaultPillars_containsYear庚午` | `.year` 기둥: `heavenlyStem == "庚"`, `earthlyBranch == "午"` | 3 |
| TA-06 | `test_mockOriginProvider_dayMasterLine_contains丙火` | `dayMasterLine`에 "丙火" 포함 확인 | 5 |
| TA-07 | `test_originCard_pillarMap_builtCorrectly` | `Dictionary(uniqueKeysWithValues:)` 로직 직접 호출, 4키 존재, `.day` 키의 `heavenlyStem == "丙"` | 3 |
| TA-08 | `test_originCard_precondition_failsForWrongCount` | `pillars.count != 4`인 mock을 사용할 때 `precondition` 호출됨을 명시적으로 문서화. 실제 XCTest에서는 `XCTExpectFailure` 또는 해당 케이스를 런타임 불가(fatalError)로 표시 | 6 |
| TA-09 | `test_categoriesSection_displayOrder_isFixed` | `[.elements, .tenGods, .daewoon, .hapchung, .yongsin]` 순서 하드코딩 검증 | 7 |
| TA-10 | `test_categoriesSection_routeMapping_elements→elements` | `route(for: .elements) == .elements` | 9 |
| TA-11 | `test_categoriesSection_routeMapping_tenGods→tenGods` | `route(for: .tenGods) == .tenGods` | 10 |
| TA-12 | `test_categoriesSection_routeMapping_daewoon→daewoonPlaceholder` | `route(for: .daewoon) == .daewoonPlaceholder` | 11 |
| TA-13 | `test_categoriesSection_routeMapping_hapchung→hapchungPlaceholder` | `route(for: .hapchung) == .hapchungPlaceholder` | 12 |
| TA-14 | `test_categoriesSection_routeMapping_yongsin→yongsinPlaceholder` | `route(for: .yongsin) == .yongsinPlaceholder` | 13 |
| TA-15 | `test_categoryCard_badge_nilWhenMockHasNil` | `MockSajuCategoriesProvider.defaultCategories`에서 `.tenGods`의 `badge == nil` | 8 |
| TA-16 | `test_categoryCard_badge_nonNilWhenMockHasBadge` | `.elements`의 `badge == "부족: 水"`, `.daewoon`의 `badge == "전환기"` | 8 |
| TA-17 | `test_categoriesSection_missingSlot_usesPlaceholder` | `MockSajuCategoriesProvider(categories: [])` 주입 시 5슬롯 모두 nil(데이터 없음) — lookup 결과가 nil | 7 |
| TA-18 | `test_pillarCell_isDayMaster_trueOnlyForDay` | `displayOrder`에서 `.day`만 `isDayMaster: true`가 되는 로직 검증 | 4 |
| TA-19 | `test_columnLabel_매핑` | `label(for:)` 함수가 hour→"時", day→"日", month→"月", year→"年" 반환 | 2 |

> TA-08(precondition)은 Swift에서 `precondition` 실패를 XCTest로 포착할 수 없으므로,
> 해당 테스트는 `XCTExpectFailure { }` 블록 또는 별도 주석으로 "런타임 fatalError 발생"
> 사실을 명시하고, 실제 앱에서 4개 아닌 배열을 주입하면 크래시함을 문서화한다.

---

## 6. UI Test Plan

파일: `WoontechUITests/Saju/SajuAboveFoldUITests.swift`

모든 테스트는 `-resetOnboarding -openSajuTab` 으로 앱을 실행한다.

| ID | 테스트명 | 검증 방법 | AC |
|---|---|---|---|
| TU-01 | `test_originCard_existsAtTopOfContent` | `app.otherElements["SajuOriginCard"].waitForExistence(timeout: 5)` | 1 |
| TU-02 | `test_originCard_headerLabel_내사주원국` | `staticTexts["SajuOriginCardHeaderLabel"].label == "내 사주 원국"` | 1 |
| TU-03 | `test_pillarCells_allFourExist` | `SajuPillarCell_hour`, `SajuPillarCell_day`, `SajuPillarCell_month`, `SajuPillarCell_year` 모두 `exists` | 2 |
| TU-04 | `test_pillarCells_day_has丙火_inLabel` | `SajuPillarCell_day.label`에 "日", "丙", "午" 포함(accessibility label 검증) | 3 |
| TU-05 | `test_pillarCells_hour_has庚申` | `SajuPillarCell_hour.label`에 "庚", "申" 포함 | 3 |
| TU-06 | `test_dayMasterLine_text_contains丙火` | `staticTexts["SajuDayMasterLine"].label`에 "丙火" 포함 | 5 |
| TU-07 | `test_dayMasterCell_hasIsHeaderTrait` | `SajuPillarCell_day`의 accessibility traits에 `.isHeader` 포함 (or label에 강조 정보) | 4, 17 |
| TU-08 | `test_viewAllButton_noopDoesNotPush` | `SajuOriginCardViewAllButton` 탭 후 NavigationStack이 변경되지 않음(새 destination identifier 없음) | 15 |
| TU-09 | `test_viewAllButton_accessibilityHint_준비중` | `SajuOriginCardViewAllButton.accessibilityHint == "준비중"` | 15 |
| TU-10 | `test_detailSectionHeader_exists` | `staticTexts["SajuDetailSectionHeader"].exists` | 1, 7 |
| TU-11 | `test_allFiveCategoryCards_exist` | 5개 `SajuCategoryCard_{kind}` identifier 모두 존재 | 7 |
| TU-12 | `test_categoryCard_elements_summary` | `SajuCategoryCard_elements.label`에 "오행 분포", "火 3" 포함 | 8 |
| TU-13 | `test_categoryCard_badge_elements_부족水_exists` | `SajuCategoryBadge_elements.exists`, `label == "부족: 水"` | 8 |
| TU-14 | `test_categoryCard_badge_tenGods_hidden` | `SajuCategoryBadge_tenGods.exists == false` | 8 |
| TU-15 | `test_categoryCard_elements_tap_pushesElements` | `SajuCategoryCard_elements` 탭 → `SajuPlaceholderDestination_elements.waitForExistence(timeout: 3)` | 9 |
| TU-16 | `test_categoryCard_tenGods_tap_pushesTenGods` | 위와 동일, destination = `tenGods` | 10 |
| TU-17 | `test_categoryCard_daewoon_tap_pushesDaewoon` | destination = `daewoon` | 11 |
| TU-18 | `test_categoryCard_hapchung_tap_pushesHapchung` | destination = `hapchung` | 12 |
| TU-19 | `test_categoryCard_yongsin_tap_pushesYongsin` | destination = `yongsin` | 13 |
| TU-20 | `test_evidence근거보기_tap_sameAsCardTap` | `SajuCategoryEvidence_elements` 탭 → `SajuPlaceholderDestination_elements` 출현(단일 hit-test 확인) | 14 |
| TU-21 | `test_dynamicType_xl_categoryCard_summaryNotTruncated` | `UIContentSizeCategoryOverride=UICTContentSizeCategoryXL` 환경 설정 후 `SajuCategoryCard_elements.frame.height > 44` (텍스트 wrapping으로 높이 증가) | 16 |
| TU-22 | `test_categoryCard_hitTarget_minHeight44` | 5개 카드 각각 `frame.height >= 44` | 18 |

> **Note**: TU-21, TU-22는 iOS Simulator XCUITest에서 `frame` 크기로 간접 검증한다.
> Accessibility Inspector 기반 hit target 검증은 별도 수동 테스트로 수행한다.

---

## 7. Risks / Open Questions

1. **T17 기존 테스트 충돌**: WF4-01의 `SajuTabFoundationUITests.test_sajuContent_placeholderVisible()`(T17)이 `SajuTabContentPlaceholderText` identifier를 찾는다. `SajuTabContentView`로 교체 후 이 테스트가 깨진다. **대응**: T17을 `XCTSkip` 처리하거나 스펙 요구사항 문서에 WF4-02에서 placeholder 제거를 명시하여 해당 테스트를 삭제한다.

2. **precondition 테스트 불가**: Swift의 `precondition`은 XCTest 내에서 포착할 수 없다. TA-08은 코드 리뷰 수준 검증이며, 런타임 보장은 mock 주입 제한으로 달성한다.

3. **`SajuPlaceholderDestinationView`의 identifier**: TU-15~19는 `SajuPlaceholderDestination_{key}` identifier를 사용하는데, 이는 WF4-01 `SajuRouteDestinations.swift`에서 이미 선언되어 있다. 변경 없이 재사용 가능.

4. **Dynamic Type 셀 겹침**: 원국 4-column HStack에서 Dynamic Type XL 시 한자 셀이 overlap될 수 있다. `frame(maxWidth: .infinity)`만으로 부족하면 `fixedSize(horizontal: false, vertical: true)`를 천간/지지 박스에도 적용하거나, 전체 `LazyVGrid`로 전환하는 것을 검토한다.

5. **일간 강조 배경 토큰 선택**: `dayMasterHighlight`를 `gray2(#D6D6D6)`로 제안했으나 디자인 확정 필요. `gray(#F2F2F2)`와 구분이 충분한지 시각 확인 필요.

6. **"근거 보기" 단일 hit-test**: `SajuCategoryEvidence_{kind}` Text가 `Button` 내부에 있으므로 별도 `.onTapGesture`가 없다면 부모 Button이 모든 tap을 처리한다. Text에 `.allowsHitTesting(false)` 적용이 필요한지는 테스트 실행 후 판단한다.

7. **`SajuCategoriesSection` 내 `onNavigate` 클로저 타입**: 클로저가 `@escaping`으로 선언되어야 View body 밖에서 저장될 경우에 대비한다. SwiftUI View에서 inline 클로저이면 불필요하지만, 별도 private 함수로 추출 시 필요.
