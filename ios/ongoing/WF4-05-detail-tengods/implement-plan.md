# implement-plan.md — WF4-05 십성 분석 상세 (v2)

---

## 1. Goal

`SajuTabView` NavigationStack의 `.tenGods` 라우트 목적지를 현재의 placeholder에서
완전한 `SajuTenGodsDetailView`로 교체한다. 5그룹 분포 바 차트, 핵심 십성 Top-3 카드,
부재 경고 카드, 학습 유도 카드를 포함하며, 독립 provider `SajuTenGodsDetailProviding`을
통해 데이터를 주입받는다.

---

## 2. Affected Files

### Modified
| 경로 | 변경 내용 |
|------|-----------|
| `Woontech/Features/Saju/Providers/SajuTenGodsDetailProviding.swift` | 기존 최소 시그니처(`summaryLine`)를 전체 모델·프로토콜·Mock으로 교체 |
| `Woontech/Features/Saju/SajuRouteDestinations.swift` | `.tenGods` 케이스를 `SajuPlaceholderDestinationView` → `SajuTenGodsDetailView`로 교체 |
| `Woontech/Shared/DesignTokens.swift` | 핵심 배지·부재 빨강 토큰 추가 (`coreBadgeBg`, `absentRed`, `absentRedLight`) |

### New
| 경로 | 설명 |
|------|------|
| `Woontech/Features/Saju/Detail/TenGods/SajuTenGodsDetailView.swift` | 메인 View + 5개 서브-컴포넌트 |
| `WoontechTests/Saju/SajuTenGodsDetailViewTests.swift` | 단위 테스트 (AC#3–#11, #17) |
| `WoontechUITests/Saju/SajuTenGodsDetailUITests.swift` | UI 테스트 (AC#1–#2, #12–#16, #18–#19) |

---

## 3. Data Model / State Changes

### 3.1 새 데이터 구조체 (in `SajuTenGodsDetailProviding.swift`)

```
struct TenGodGroup: Equatable
  name: String        // "비겁" | "식상" | "재성" | "관성" | "인성"
  han: String         // 한자 (예: "比劫")
  meaning: String     // 의미 설명 (예: "주체성·동료")
  items: [String]     // 길이 정확히 2 — precondition
  counts: [Int]       // 길이 정확히 2, items와 1:1 대응 — precondition
  total: Int          // 0–8 (8점 만점)
  isCore: Bool
  isAbsent: Bool

struct CoreTenGod: Equatable
  name: String              // "정재"
  han: String               // "正財"
  count: Int                // 등장 횟수
  meaning: String           // 설명 본문
  investImplication: String // 투자 함의 (💹 박스)

struct AbsentWarning: Equatable
  groupTitle: String  // "식상(식신·상관) 부재"
  items: String       // (현재 미사용 표출, 보관용)
  copy: String        // 경고 본문

struct LearnEntry: Equatable
  title: String         // "십성이란 무엇인가요?"
  durationLabel: String // "3분"
  levelLabel: String    // "초급"
  lessonId: String      // "L-TEN-001"
```

### 3.2 프로토콜 변경

```
protocol SajuTenGodsDetailProviding {
    var summaryHeadline: String { get }   // 기존 summaryLine 대체
    var summaryBody: String { get }       // 신규
    var groups: [TenGodGroup] { get }    // count == 5 (precondition)
    var topThree: [CoreTenGod] { get }   // count == 3 (precondition)
    var absentWarning: AbsentWarning? { get }
    var learnEntry: LearnEntry? { get }
}
```

기존 `summaryLine` 프로퍼티는 삭제하고 `summaryHeadline` + `summaryBody`로 분리.  
`SajuTabDependencies`의 `tenGodsDetail` 필드 타입(`any SajuTenGodsDetailProviding`)은
그대로 유지 — 재컴파일만 필요.

### 3.3 Mock 기본값 (`MockSajuTenGodsDetailProvider`)

- `summaryHeadline`: "정재가 중심인 사주"
- `summaryBody`: "꼼꼼하고 안정을 추구하는 기질로 투자 시 검증된 패턴을 선호합니다."
- `groups` (5개, 순서 [비겁, 식상, 재성, 관성, 인성]):
  - 비겁: items=["비견","겁재"], counts=[1,0], total=1, isCore=false, isAbsent=false
  - 식상: items=["식신","상관"], counts=[0,0], total=0, isCore=false, isAbsent=true
  - 재성: items=["편재","정재"], counts=[0,2], total=2, isCore=true, isAbsent=false
  - 관성: items=["편관","정관"], counts=[0,1], total=1, isCore=false, isAbsent=false
  - 인성: items=["편인","정인"], counts=[0,1], total=1, isCore=false, isAbsent=false
- `topThree` (3개):
  - [0] 정재, "正財", count=2, meaning="...", investImplication="..."
  - [1] 비견, "比肩", count=1, meaning="...", investImplication="..."
  - [2] 정인, "正印", count=1, meaning="...", investImplication="..."
- `absentWarning`: groupTitle="식상(식신·상관) 부재", copy="창의적 직관 매매보다 검증된 패턴 매매가 내 성향에 맞아요"
- `learnEntry`: title="십성이란 무엇인가요?", durationLabel="3분", levelLabel="초급", lessonId="L-TEN-001"

### 3.4 DesignTokens 추가

```swift
// 십성 배지·경고 색상
static let coreBadgeBg    = ink           // "핵심" 배지 배경 (검정)
static let absentRed      = fireColor     // 부재 텍스트·카드 테두리 (재사용)
static let absentRedLight = Color(red: 1.0, green: 0.9, blue: 0.9)  // 경고 카드 박스 배경
```

### 3.5 상태 변경 없음

`SajuTenGodsDetailView`는 stateless — `let provider: any SajuTenGodsDetailProviding`만
보유. NavigationStack path는 부모 `SajuTabView`가 관리하며 변경 없음.

---

## 4. Implementation Steps

> 각 단계는 개별적으로 빌드·실행 가능한 크기로 분리한다.

### Step 1 — DesignTokens 토큰 추가
- `DesignTokens.swift`에 `coreBadgeBg`, `absentRed`, `absentRedLight` 3개 정적 프로퍼티 추가.
- **검증**: 빌드 통과 (토큰 이름 오타 없음).

### Step 2 — Provider 모델 정의
- `SajuTenGodsDetailProviding.swift`에 `TenGodGroup`, `CoreTenGod`, `AbsentWarning`,
  `LearnEntry` 구조체 선언 (Equatable).
- 프로토콜을 새 6-프로퍼티 버전으로 교체 (기존 `summaryLine` 삭제).
- `MockSajuTenGodsDetailProvider`를 풀 버전으로 재작성 (섹션 3.3 기본값).
- **검증**: 빌드 통과. `SajuTabDependencies.tenGodsDetail` 참조 재컴파일 확인.

### Step 3 — Sort Helper 함수
- `SajuTenGodsDetailView.swift` 파일 생성 (빈 View stub 포함).
- 파일 상단에 `sortedTenGodGroups(_:)` 자유 함수 추가 (내부에서 `validateGroups` 호출 후 precondition 이중 방어):
  ```
  let order = ["비겁", "식상", "재성", "관성", "인성"]
  try? validateGroups(groups)           // throws-based check (testable)
  precondition(groups.count == 5, ...) // runtime crash guard
  compactMap으로 name 매칭 후 재정렬
  precondition(result.count == 5, ...)
  ```
- groups 수 검증용 **`internal throws` 헬퍼** (`validateGroups(_:) throws`) 추가:
  ```
  internal func validateGroups(_ groups: [TenGodGroup]) throws {
      guard groups.count == 5 else {
          throw TenGodsValidationError.invalidGroupCount(groups.count)
      }
  }
  ```
- 각 그룹 items/counts 길이 검증을 위한 **`internal throws` 헬퍼** (`validateGroupLengths(_:) throws`) 추가.
  프로덕션 코드는 이 헬퍼 호출 뒤 `precondition` 이중 방어:
  ```
  internal func validateGroupLengths(_ groups: [TenGodGroup]) throws {
      for g in groups {
          guard g.items.count == 2, g.counts.count == 2 else {
              throw TenGodsValidationError.invalidItemsLength(name: g.name)
          }
      }
  }
  ```
- `topThree` 검증용 **`internal throws` 헬퍼** (`validateTopThree(_:) throws`) 추가:
  ```
  internal func validateTopThree(_ topThree: [CoreTenGod]) throws {
      guard topThree.count == 3 else {
          throw TenGodsValidationError.invalidTopThreeCount(topThree.count)
      }
  }
  ```
- `TenGodsValidationError: Error` enum 선언 (동일 파일 내).
- 이 헬퍼들은 `@testable import`로 T23/T24/T25에서 `XCTAssertThrowsError` 호출에 사용된다.
- **검증**: 빌드 통과.

### Step 4 — 요약 카드 (`TenGodsSummaryCard`)
- private struct: 섹션 라벨 "십성 요약" + headline(bold 13pt) + body(muted 10pt, fixedSize).
- Identifier: `TenGodsSummaryCard`, `TenGodsSummaryHeadline`, `TenGodsSummaryBody`.
- `SajuTenGodsDetailView.body`에서 ScrollView 안 VStack의 첫 번째 자식으로 배치.
- NavBar 타이틀 "십성 분석" (inline), root Color.clear marker(`SajuTenGodsDetailView`).
- **검증**: Preview에서 요약 카드만 표시.

### Step 5 — 5그룹 분포 카드 (`TenGodsDistributionCard`, `TenGodsGroupRow`)
- `TenGodsGroupRow` private struct:
  - 상단 HStack: 좌(name bold 12pt + han serif 9pt muted + isCore 시 핵심 배지) / 우(isAbsent 빨강 "부재 ⚠" 또는 muted "{total}/8").
  - 막대 바(높이 7pt, GeometryReader): fillRatio = `min(CGFloat(total) / 3.0, 1.0)`, isAbsent → `DesignTokens.line2`, 정상 → `DesignTokens.ink`.
  - 막대 아래 보조 라인: 좌 meaning(muted 10pt) / 우 displayedItems 텍스트(`counts[i]>0` 인 items만 " · " join, 없으면 "—"). **우측 Text에 `.accessibilityIdentifier("TenGodsDisplayedItems_\(group.name)")` 부여** — T41/T42 필수.
  - Identifier: `TenGodsGroupRow_{name}`.
  - VoiceOver: `"{name} {han}, {meaning}, {total}점 8점 만점 중"` (isCore → trait `.isSelected` 혹은 label에 "핵심 " 접두어, isAbsent → label에 "부재 경고, " 접두어).
- `TenGodsDistributionCard`: 섹션 라벨 "5그룹 분포" + ForEach(sortedGroups). Identifier: `TenGodsDistributionCard`.
- **검증**: Preview에서 5행 바 차트 확인.

### Step 6 — 핵심 십성 카드 (`TenGodsCoreSection`, `TenGodsCoreCard`)
- `TenGodsCoreCard` private struct:
  - 상단 HStack: 좌(name bold 13pt + han serif 9pt muted) / 우(`×{count}` muted).
  - 본문: meaning muted 10pt, fixedSize.
  - 하단 박스(`gray2` 배경, 8pt 패딩): 💹 + investImplication muted 9pt, fixedSize.
  - 첫 번째 카드(`isFirst: Bool`): 배경 `gray`, 테두리 `line2`; 나머지: 테두리 `line3`.
  - Identifier: `TenGodsCoreCard_{index}`.
  - VoiceOver: `"{name} {han}, {count}회, {meaning}. 투자 함의: {investImplication}"`.
  - 투자 함의 박스 Identifier: `TenGodsInvestImplication_{index}`.
- `TenGodsCoreSection`: 섹션 라벨 "나의 핵심 십성" + ForEach enumerated(topThree). Identifier: `TenGodsCoreSection`.
- `SajuTenGodsDetailView`에서 topThree precondition 검증 후 섹션 배치.
- **검증**: Preview에서 3개 카드, 첫 번째 강조 확인.

### Step 7 — 부재 경고 카드 (`TenGodsAbsentWarningCard`)
- private struct:
  - 카드 전체: 빨강 테두리(`absentRed`, lineWidth 1).
  - 섹션 라벨 "주의 — 부재 십성" (absentRed, caption2).
  - `groupTitle` bold 12pt.
  - copy 박스: `absentRedLight` 배경, muted 10pt, fixedSize.
  - Identifier: `TenGodsAbsentWarningCard`.
  - VoiceOver: `"주의, 부재 십성, {groupTitle}. {copy}"`.
- `SajuTenGodsDetailView`에서 `if let absentWarning` 조건부 렌더.
- **검증**: Preview(with warning) / Preview(no warning)으로 표시·숨김 확인.

### Step 8 — 학습 유도 카드 (`TenGodsLearnEntryCard`)
- private struct:
  - HStack: 좌(📚 큰 이모지) + 우(title bold 12pt + "{durationLabel} 레슨 · {levelLabel}" muted caption2) + Spacer + `›`.
  - Identifier: `TenGodsLearnEntryCard`.
  - VoiceOver: `"레슨 진입, {title}, {durationLabel}, {levelLabel}"`.
  - `Button` 또는 `.onTapGesture` → `onNavigate(.lesson(id: entry.lessonId))`.
- `SajuTenGodsDetailView`에 `onNavigate: (SajuRoute) -> Void` 파라미터 추가
  (Elements 패턴과 달리 학습 라우트 push가 필요하므로 추가).
- `if let learnEntry` 조건부 렌더.
- **검증**: Preview에서 탭 동작 (NavigationStack 래핑).

### Step 9 — DisclaimerView 배치 및 전체 레이아웃 완성
- ScrollView > VStack(spacing: 10):
  1. TenGodsSummaryCard
  2. TenGodsDistributionCard
  3. TenGodsCoreSection
  4. TenGodsAbsentWarningCard (optional)
  5. TenGodsLearnEntryCard (optional)
  6. DisclaimerView()
- 좌우 padding 16pt, 수직 padding 16pt.
- Background: `DesignTokens.bg`.
- **검증**: 전체 스크롤 레이아웃 Preview.

### Step 10 — Route 연결
- `SajuRouteDestinations.swift`에서 `.tenGods` 케이스를 다음으로 교체:
  ```swift
  case .tenGods:
      SajuTenGodsDetailView(
          provider: deps.tenGodsDetail,
          onNavigate: { route in /* navigationPath append handled by SajuTabView */ }
      )
  ```
  **Option A 채택** (변경 범위 최소, Option B는 사용하지 않음):
  - `SajuRouteDestinations.swift`의 destination-builder 함수 시그니처에 `onNavigate: (SajuRoute) -> Void`
    파라미터를 추가한다.
  - `SajuTabView`의 `.navigationDestination` 클로저 안에서 `onNavigate: { route in navigationPath.append(route) }`
    를 전달한다.
  - `SajuElementsDetailView` 등 `onNavigate`가 불필요한 기존 뷰는 `onNavigate` 파라미터를 받지 않으므로
    해당 builder 함수에는 변경이 없다.
- **검증**: 시뮬레이터에서 "십성 분석" 카드 탭 → 실화면 전환, 학습 유도 탭 → lesson placeholder 전환.

### Step 11 — 단위 테스트 작성
- `WoontechTests/Saju/SajuTenGodsDetailViewTests.swift` 신규 작성 (단위 테스트 계획 참조).

### Step 12 — UI 테스트 작성
- `WoontechUITests/Saju/SajuTenGodsDetailUITests.swift` 신규 작성 (UI 테스트 계획 참조).
- 필요한 launch argument 처리:
  - `-sajuTenGodsNoAbsentWarning`: `MockSajuTenGodsDetailProvider(absentWarning: nil)` 주입
  - `-sajuTenGodsNoLearnEntry`: `MockSajuTenGodsDetailProvider(learnEntry: nil)` 주입

---

## 5. Unit Test Plan

파일: `WoontechTests/Saju/SajuTenGodsDetailViewTests.swift`

### Group A — 프로토콜 분리 (AC#17)
| ID | 테스트명 | 내용 |
|----|----------|------|
| T1 | `test_protocol_tenGodsNotCategories` | `SajuTenGodsDetailProviding` 구현체를 `SajuCategoriesProviding` 변수에 대입 시도가 컴파일 에러(코드리뷰). 런타임: 두 타입이 다름 XCTAssert |
| T2 | `test_protocol_tenGodsNotElements` | `SajuTenGodsDetailProviding` 구현체를 `SajuElementsDetailProviding` 변수에 대입 시도가 컴파일 에러(코드리뷰). 런타임: 두 타입이 다름 XCTAssert |

### Group B — Mock 기본값 (AC#3, AC#11)
| ID | 테스트명 | 내용 |
|----|----------|------|
| T3 | `test_mock_summaryHeadline` | `== "정재가 중심인 사주"` |
| T4 | `test_mock_summaryBody_notEmpty` | `.isEmpty == false` |
| T5 | `test_mock_groupsCount5` | `groups.count == 5` |
| T6 | `test_mock_groupsOrder` | `groups[0].name=="비겁"`, `[1]=="식상"`, `[2]=="재성"`, `[3]=="관성"`, `[4]=="인성"` |
| T7 | `test_mock_재성_isCore` | `groups.first{$0.name=="재성"}?.isCore == true` |
| T8 | `test_mock_식상_isAbsent` | `groups.first{$0.name=="식상"}?.isAbsent == true` |
| T9 | `test_mock_topThreeCount3` | `topThree.count == 3` |
| T10 | `test_mock_topThree_정재_count2` | `topThree[0].name == "정재"`, `topThree[0].count == 2` |
| T11 | `test_mock_absentWarning_notNil` | `absentWarning != nil` |
| T12 | `test_mock_absentWarning_groupTitle` | `== "식상(식신·상관) 부재"` |
| T13 | `test_mock_learnEntry_notNil` | `learnEntry != nil` |
| T14 | `test_mock_learnEntry_lessonId` | `== "L-TEN-001"` |

### Group C — 막대 채움 비율 (AC#7)
| ID | 테스트명 | 내용 |
|----|----------|------|
| T15 | `test_fillRatio_total2_is66pct` | `min(2.0/3.0, 1.0) ≈ 0.667` (accuracy: 0.001) |
| T16 | `test_fillRatio_total3_is100pct` | `min(3.0/3.0, 1.0) == 1.0` |
| T17 | `test_fillRatio_total0_is0pct` | `min(0.0/3.0, 1.0) == 0.0` |
| T18 | `test_fillRatio_total4_clamped100pct` | `min(4.0/3.0, 1.0) == 1.0` |

### Group D — 표출 십성 텍스트 (AC#8)
| ID | 테스트명 | 내용 |
|----|----------|------|
| T19 | `test_displayedItems_oneActive` | items=["비견","겁재"], counts=[1,0] → "비견" |
| T20 | `test_displayedItems_allZero` | counts=[0,0] → "—" |
| T21 | `test_displayedItems_bothActive` | counts=[1,1] → "비견 · 겁재" |

### Group E — precondition / validation (AC#9)

**전략**: `precondition()` 자체는 프로세스를 종료하므로 XCTest에서 직접 검증 불가. 대신 동일 조건 검사를
수행하는 `internal throws` 헬퍼(`validateGroups(_:) throws`, `validateGroupLengths(_:) throws`)를 별도
선언하고 `@testable import`로 단위 테스트에서 호출한다. 프로덕션 코드는 이 헬퍼를 호출한 뒤 `precondition`으로
이중 방어한다.

| ID | 테스트명 | 내용 |
|----|----------|------|
| T22 | `test_sortedGroups_length5_succeeds` | 순서 뒤섞은 5개 배열 → 정렬 성공, 각 name 확인 |
| T23 | `test_validateGroups_lengthNot5_throws` | 4개 배열 → `validateGroups` throws; `XCTAssertThrowsError` |
| T24 | `test_validateGroupLengths_itemsCountNot2_throws` | items.count=1 그룹 → `validateGroupLengths` throws |

### Group F — topThree validation (AC#10)

**전략**: 동일하게 `validateTopThree(_:) throws` 헬퍼 선언 후 단위 테스트에서 호출.

| ID | 테스트명 | 내용 |
|----|----------|------|
| T25 | `test_validateTopThree_countNot3_throws` | 2개 배열 → `validateTopThree` throws; `XCTAssertThrowsError` |

### Group G — Optional 카드 nil/non-nil (AC#12–15)
| ID | 테스트명 | 내용 |
|----|----------|------|
| T26 | `test_absentWarningNonNil_viewCreates` | `provider.absentWarning != nil` + View 생성 crash 없음 |
| T27 | `test_absentWarningNil_viewCreates` | `Mock(absentWarning: nil)` + View 생성 crash 없음 |
| T28 | `test_learnEntryNonNil_viewCreates` | `provider.learnEntry != nil` + View 생성 crash 없음 |
| T29 | `test_learnEntryNil_viewCreates` | `Mock(learnEntry: nil)` + View 생성 crash 없음 |

### Group H — SajuTabDependencies 통합 (AC#17)
| ID | 테스트명 | 내용 |
|----|----------|------|
| T30 | `test_deps_tenGodsDetailReplaceable` | Stub provider(summaryHeadline="stub") 주입 → deps.tenGodsDetail.summaryHeadline == "stub" |

---

## 6. UI Test Plan

파일: `WoontechUITests/Saju/SajuTenGodsDetailUITests.swift`  
공통 setup: `-resetOnboarding -openSajuTab` 실행 → `SajuTabRoot` 대기 → `SajuNavPush_tenGods` 탭.

### 6.1 Navigation (AC#1, AC#2)
| ID | 테스트명 | 내용 |
|----|----------|------|
| T31 | `testNavPush_tenGods_showsDetailView` | `SajuNavPush_tenGods` 탭 → `app.otherElements["SajuTenGodsDetailView"]` 존재 |
| T32 | `testNavBarTitle_is십성분석` | `app.navigationBars.staticTexts["십성 분석"]` 존재 |
| T33 | `testBackButton_popsToSajuHome` | back 버튼 탭 → `SajuTabRoot` 존재 |

### 6.2 요약 카드 (AC#3)
| ID | 테스트명 | 내용 |
|----|----------|------|
| T34 | `testSummaryCard_headlineVisible` | `TenGodsSummaryHeadline` 존재, `.label.isEmpty == false` |
| T35 | `testSummaryCard_bodyVisible` | `TenGodsSummaryBody` 존재 |
| T36 | `testSummaryCard_headlineMatchesMock` | `.label == "정재가 중심인 사주"` |

### 6.3 5그룹 분포 (AC#4–8)
| ID | 테스트명 | 내용 |
|----|----------|------|
| T37 | `testDistribution_fiveGroupRowsExist` | `TenGodsGroupRow_비겁` ~ `TenGodsGroupRow_인성` 5개 존재 |
| T38 | `testDistribution_orderIsSpec` | Y좌표 순서: 비겁 < 식상 < 재성 < 관성 < 인성 |
| T39 | `testDistribution_재성_hasCoreBadge` | `TenGodsCoreBadge_재성` (또는 a11y label에 "핵심" 포함) 존재 |
| T40 | `testDistribution_식상_isAbsent_accessibilityLabel` | `TenGodsGroupRow_식상`.label 에 "부재" 포함 |
| T41 | `testDistribution_비겁_displayedItems` | 비겁 행 보조 라인 우측 텍스트가 "비견" (counts=[1,0]) |
| T42 | `testDistribution_식상_displayedItemsIsEmpty` | 식상 행 보조 라인 우측 텍스트가 "—" (counts=[0,0]) |

### 6.4 핵심 십성 카드 (AC#10, AC#11)
| ID | 테스트명 | 내용 |
|----|----------|------|
| T43 | `testCoreSection_threeCardsExist` | `TenGodsCoreCard_0`, `_1`, `_2` 존재 |
| T44 | `testCoreSection_firstCard_containsProvider` | `TenGodsCoreCard_0`.label에 "정재" 포함 |
| T45 | `testCoreSection_firstCard_differentBg` | `TenGodsCoreCard_0`.frame.height > 0 (표시 확인); 시각적 배경 구분은 코드리뷰로 검증 |

### 6.5 부재 경고 카드 (AC#12, AC#13)
| ID | 테스트명 | 내용 |
|----|----------|------|
| T46 | `testAbsentWarning_visibleByDefault` | 스크롤 후 `TenGodsAbsentWarningCard` 존재 |
| T47 | `testAbsentWarning_accessibilityLabel_contains주의` | `.label`에 "주의" 포함 |
| T48 | `testAbsentWarning_hiddenWhenNil` | `-sajuTenGodsNoAbsentWarning` 실행 → `TenGodsAbsentWarningCard` NOT exist |

### 6.6 학습 유도 카드 (AC#14, AC#15)
| ID | 테스트명 | 내용 |
|----|----------|------|
| T49 | `testLearnEntry_visibleByDefault` | 스크롤 후 `TenGodsLearnEntryCard` 존재 |
| T50 | `testLearnEntry_tap_pushesLessonRoute` | 카드 탭 → `SajuPlaceholderDestination_lesson` + Identifier "L-TEN-001" 존재 |
| T51 | `testLearnEntry_hiddenWhenNil` | `-sajuTenGodsNoLearnEntry` 실행 → `TenGodsLearnEntryCard` NOT exist |

### 6.7 Disclaimer (AC#16)
| ID | 테스트명 | 내용 |
|----|----------|------|
| T52 | `testDisclaimer_existsAfterScroll` | swipeUp 후 `DisclaimerText` 존재 및 "학습·참고용" 포함 |

### 6.8 VoiceOver 포커스 순서 (AC#18)
| ID | 테스트명 | 내용 |
|----|----------|------|
| T53 | `testA11yOrder_summaryBeforeDistribution` | `TenGodsSummaryCard`.maxY < `TenGodsGroupRow_비겁`.minY |
| T54 | `testA11yOrder_distributionBeforeCore` | `TenGodsGroupRow_인성`.maxY < `TenGodsCoreCard_0`.minY |
| T57 | `testA11yOrder_coreBeforeAbsentWarning` | `TenGodsCoreCard_2`.maxY < `TenGodsAbsentWarningCard`.minY (기본 mock, absentWarning 있음) |
| T58 | `testA11yOrder_absentWarningBeforeLearnEntry` | `TenGodsAbsentWarningCard`.maxY < `TenGodsLearnEntryCard`.minY (기본 mock, 둘 다 있음) |
| T59 | `testA11yOrder_learnEntryBeforeDisclaimer` | `TenGodsLearnEntryCard`.maxY < `DisclaimerText`.minY (기본 mock) |

### 6.9 Dynamic Type (AC#19)
| ID | 테스트명 | 내용 |
|----|----------|------|
| T55 | `testDynamicTypeXL_investImplicationNotTruncated` | env `UIContentSizeCategoryOverride=UICTContentSizeCategoryXL` → `TenGodsInvestImplication_0`.label에 "…" 미포함 |
| T56 | `testDynamicTypeXL_absentWarnCopyNotTruncated` | 동일 env → `TenGodsAbsentWarningCopy`.label에 "…" 미포함 |

---

## 7. Risks / Open Questions

### R1 — ~~`onNavigate` 클로저 전달 방법~~ (해결됨)
**Option A 채택** (Step 10에 명시). `SajuRouteDestinations.swift` destination-builder에
`onNavigate: (SajuRoute) -> Void` 파라미터를 추가하고, `SajuTabView`에서
`{ route in navigationPath.append(route) }` 전달.

### R2 — `summaryLine` 제거로 인한 WF4-01 이전 테스트 영향 (중요도: 중간)
`SajuMockProvidersTests.swift`나 `SajuTabDependenciesTests.swift` 등 기존 테스트에서
`MockSajuTenGodsDetailProvider().summaryLine`을 참조하고 있다면 컴파일 에러 발생.  
**대응**: Step 2 후 전체 빌드 → 에러 발생 파일 색출 후 `summaryHeadline` 으로 업데이트.

### R3 — `SajuNavPush_tenGods` 히든 버튼 존재 여부 (중요도: 낮음)
`SajuTabView`에 `SajuNavPush_tenGods` 버튼이 이미 존재하는지 확인 필요 (`SajuNavPush_elements`
패턴 참조). 없으면 WF4-01 코드 확인 후 동일 패턴으로 추가.

### R4 — 핵심 배지(`핵심`) VoiceOver 트레잇 표현 (중요도: 낮음)
Spec AC#5: isCore 행에 "핵심" 배지. VoiceOver AC#18: 특별 트레잇 또는 label 접두어로 표현.
배지를 별도 `accessibilityElement`로 만드는 대신 부모 행 `accessibilityLabel` 앞에
"핵심, " 접두어 추가 방식이 간결 (Elements 패턴 참조). 구현 시 결정.

### R5 — ~~`TenGodsDistributionCard` 내 보조 라인 우측 텍스트 identifier~~ (해결됨)
Step 5에 `.accessibilityIdentifier("TenGodsDisplayedItems_\(group.name)")` 부여가 명시적으로
추가되었으므로 더 이상 오픈 리스크가 아님.

### R6 — Lesson 라우트 push 확인 방법 (중요도: 낮음)
T50에서 탭 후 `SajuPlaceholderDestination_lesson` identifier와 `SajuPlaceholderDestination_lesson_Identifier`
에 "L-TEN-001"이 표시되는지 확인 — 기존 placeholder 구현(`identifier: id`)이 이를 지원함.
