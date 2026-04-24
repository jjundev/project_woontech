# implement-plan.md — WF3-02 홈 Above-the-Fold (Hero + Insights)
version: 1

---

## 1. Goal

`HomeDashboardView`의 스크롤 컨텐츠 영역에 **Hero 섹션**(투자 태도 원형 지수 + 한줄 카피)과
**Insights 섹션**(금기·일진·실천 3카드 가로 스크롤)을 구현하고, WF3-01에서 스텁만 선언된
`HeroInvestingProviding`·`InsightsProviding` 프로토콜과 Mock 구현을 완성한다.

---

## 2. Affected Files

### Modified
| Path | 변경 유형 |
|------|----------|
| `Woontech/Features/Home/Providers/HeroInvestingProviding.swift` | 프로토콜 요구사항 추가, MockHeroInvestingProvider 구현 완성 |
| `Woontech/Features/Home/Providers/InsightsProviding.swift` | InsightCard 모델 + 프로토콜 요구사항 추가, MockInsightsProvider 구현 완성 |
| `Woontech/Features/Home/HomeDashboardView.swift` | ScrollView 내 `Text("준비중")` 교체 → HeroSection + InsightsSection 삽입 |
| `Woontech/Shared/DesignTokens.swift` | Insight badge 색상 토큰 3개 추가 |
| `Woontech/App/WoontechApp.swift` | Hero mock 오버라이드 launch arg 파싱 추가 (`-mockHeroScore`, `-mockHeroDisplayName`, `-mockHeroDate`) |
| `WoontechTests/Home/HomeDashboardTests.swift` | WF3-02 단위 테스트 추가 |
| `WoontechUITests/Home/HomeDashboardUITests.swift` | WF3-02 UI 테스트 추가 |

### New
| Path | 설명 |
|------|------|
| `Woontech/Features/Home/HeroInvestingCardView.swift` | Hero 섹션 전체 뷰 (날짜 라벨 + 인사말 + 카드) |
| `Woontech/Features/Home/InsightCardView.swift` | 단일 Insight 카드 뷰 + InsightsScrollView |

---

## 3. Data Model / State Changes

### 3-A. `HeroInvestingProviding` 프로토콜 확장

```
protocol HeroInvestingProviding {
    var score: Int { get }          // 0~100 integer; view에서 clamp(0, 100)
    var oneLiner: String { get }    // 큰 본문 한줄 카피
    var displayDate: Date { get }   // 날짜 라벨 원본 값
}
```

`MockHeroInvestingProvider` 기본값:
- `score = 72`
- `oneLiner = "공격보다 관찰이 내 성향에 맞아요"`
- `displayDate = 2026-04-23 (Calendar.current)` — `DateComponents(year:2026,month:4,day:23)`

### 3-B. `InsightCard` 값 타입 (InsightsProviding.swift 내부)

```
struct InsightCard {
    let badgeLabel: String     // 예: "금기"
    let badgeColor: Color      // DesignTokens 토큰 참조 권장
    let icon: String           // SF Symbol name
    let title: String          // bold 제목
    let desc: String           // 멀티라인; \n 포함 가능
    let bottomLabel: String    // 하단 캡션, 예: "오늘의 금기"
}
```

`InsightsProviding` 프로토콜 확장:

```
protocol InsightsProviding {
    var cards: [InsightCard] { get }   // 뷰는 인덱스 0=금기, 1=일진, 2=실천 고정 매핑
}
```

`MockInsightsProvider` 기본 3카드:

| 슬롯 | badgeLabel | badgeColor | icon | title | desc | bottomLabel |
|------|-----------|-----------|------|-------|------|------------|
| 0 (금기) | "금기" | DesignTokens.tabooColor (red) | "exclamationmark.triangle" | "큰 거래 자제" | "오늘은 큰 거래보다\n작은 수익에 집중하세요" | "오늘의 금기" |
| 1 (일진) | "일진" | DesignTokens.todayColor (gray) | "sun.max" | "목(木)의 기운" | "목의 기운이 강한 날로\n새로운 시작에 좋아요" | "오늘의 일진" |
| 2 (실천) | "실천" | DesignTokens.practiceColor (green) | "checkmark.circle" | "리밸런싱 점검" | "포트폴리오를 점검하고\n목표 비중을 재조정하세요" | "오늘의 실천" |

### 3-C. DesignTokens 추가

```swift
static let tabooColor    = Color(red: 0xE5/255, green: 0x39/255, blue: 0x35/255)  // red (fireColor 재사용)
static let todayColor    = Color(red: 0x80/255, green: 0x80/255, blue: 0x80/255)  // gray (muted 재사용)
static let practiceColor = Color(red: 0x4C/255, green: 0xAF/255, blue: 0x50/255)  // green (woodColor 재사용)
```

> 기존 오행 색상과 동일 값이므로 별칭(`typealias`)으로 선언해도 무방.

### 3-D. HomeDashboardView state 변경 없음

`navigationPath: [HomeRoute]`는 기존 그대로. 하위 뷰에 `onTap: () -> Void` 클로저로 전달.

### 3-E. AC-14 동작 결정 (고정)

**empty placeholder 채택**: `InsightsProviding.cards` 배열이 3개 미만인 경우 누락 슬롯은
회색 빈 카드(accessibilityIdentifier "InsightCard_empty_{n}")로 렌더한다. 뷰는 항상 3개의
슬롯 컨테이너를 렌더하며 배열 인덱스를 Optional 안전 구독(`cards[safe: n]`)으로 접근한다.
크래시 없음. 단위 테스트에서 이 동작을 명시적으로 검증한다.

---

## 4. Implementation Steps

각 스텝은 빌드 가능 상태를 유지한다.

### Step 1 — HeroInvestingProviding 프로토콜 + Mock 완성
- `HeroInvestingProviding.swift`: 프로토콜에 `score`, `oneLiner`, `displayDate` 추가.
- `MockHeroInvestingProvider`: struct에 동일 프로퍼티 + 기본값 추가.
- **빌드 확인 기준**: `HomeDependencies.mock`이 컴파일 오류 없음.

### Step 2 — InsightCard 모델 + InsightsProviding 프로토콜 + Mock 완성
- `InsightsProviding.swift`: `import SwiftUI` 추가, `InsightCard` struct 정의, 프로토콜에 `cards: [InsightCard]` 추가.
- `MockInsightsProvider`: struct에 `cards` computed property 추가 (3카드 고정값).
- **빌드 확인 기준**: 컴파일 오류 없음.

### Step 3 — DesignTokens badge 색상 추가
- `DesignTokens.swift`에 `tabooColor`, `todayColor`, `practiceColor` static 프로퍼티 추가.
- 기존 오행 색상과 동일 RGBA면 주석으로 alias 명시.

### Step 4 — HeroInvestingCardView 구현
파일: `Woontech/Features/Home/HeroInvestingCardView.swift`

구조:

```
HeroInvestingCardView(provider, userProfile, onTap)
  VStack(alignment: .leading, spacing: 8) {
      // 날짜 라벨 (accessibilityIdentifier: "HomeHeroDate")
      Text(formattedDate)   // YYYY.MM.DD EEEE with ko_KR locale
          .font(.caption)
          .foregroundStyle(DesignTokens.muted)

      // 인사말 (accessibilityIdentifier: "HomeHeroGreeting")
      Text("\(displayName)님, 오늘의 투자 태도예요")
          .font(.subheadline)

      // 카드 전체를 Button으로 감싸기 (단일 hit-test)
      Button(action: onTap) {
          VStack(alignment: .leading, spacing: 12) {
              // 투자 관점 배지 pill
              Text("투자 관점")
                  .font(.caption2)
                  .padding(.horizontal, 8).padding(.vertical, 4)
                  .background(DesignTokens.gray).clipShape(Capsule())

              // 원형 지수 + /100
              HStack(alignment: .firstTextBaseline, spacing: 2) {
                  Text("\(clampedScore)")     // accessibilityIdentifier: "HomeHeroScore"
                      .font(.system(size: 48, weight: .bold))
                  Text("/100")
                      .font(.title3).foregroundStyle(DesignTokens.muted)
              }
              .accessibilityLabel("\(clampedScore)점")  // VoiceOver AC

              // 한줄 카피 (accessibilityIdentifier: "HomeHeroOneLiner")
              Text(provider.oneLiner)
                  .font(.body).fixedSize(horizontal: false, vertical: true)

              HStack {
                  Spacer()
                  Text("상세 보기 ›")
                      .font(.caption).foregroundStyle(DesignTokens.muted)
              }
          }
          .padding(16)
          .background(DesignTokens.gray)
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .contentShape(Rectangle())   // 단일 hit-test 보장
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("HomeHeroCard")
  }
  .padding(.horizontal, 16)
  .padding(.top, 16)
```

- `clampedScore` = `min(max(0, provider.score), 100)` (내부 computed var)
- `formattedDate`: `DateFormatter(dateFormat: "yyyy.MM.dd EEEE", locale: Locale(identifier: "ko_KR"))`
- 날짜 포맷터는 파일 모듈 레벨 private let으로 캐싱 (DateFormatter 생성 비용 절감)

### Step 5 — InsightCardView + InsightsScrollView 구현
파일: `Woontech/Features/Home/InsightCardView.swift`

**InsightCardView** (단일 카드):

```
InsightCardView(card: InsightCard, onTap: () -> Void)
  Button(action: onTap) {
      VStack(alignment: .leading, spacing: 8) {
          // 상단 badge pill
          Text(card.badgeLabel)
              .font(.caption2).foregroundStyle(.white)
              .padding(.horizontal, 8).padding(.vertical, 4)
              .background(card.badgeColor).clipShape(Capsule())

          // 아이콘 (large)
          Image(systemName: card.icon)
              .font(.system(size: 36))
              .foregroundStyle(card.badgeColor)

          // title bold
          Text(card.title)
              .font(.headline).fixedSize(horizontal: false, vertical: true)

          // desc multiline
          Text(card.desc)
              .font(.caption).foregroundStyle(DesignTokens.muted)
              .fixedSize(horizontal: false, vertical: true)

          Spacer(minLength: 4)

          // 하단 캡션
          Text(card.bottomLabel)
              .font(.caption2).foregroundStyle(DesignTokens.muted)
      }
      .padding(12)
      .frame(width: 160)          // 가로 고정 너비
      .background(DesignTokens.gray)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .contentShape(Rectangle())
  }
  .buttonStyle(.plain)
  .accessibilityLabel("\(card.badgeLabel), \(card.title)")  // VoiceOver AC
```

**InsightPlaceholderCard** (내부 private struct, AC-14 빈 슬롯용):

```
private struct InsightPlaceholderCard: View { ... }
// 회색 라운드 사각형, accessibilityIdentifier: "InsightCard_empty_{index}"
```

**InsightsScrollView**:

```
InsightsScrollView(provider: InsightsProviding, onTabooTap, onTodayTap, onPracticeTap)
  VStack(alignment: .leading, spacing: 12) {
      Text("오늘의 인사이트")
          .font(.headline).padding(.horizontal, 16)
          .accessibilityIdentifier("HomeInsightsSectionLabel")

      ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
              // 슬롯 0: 금기
              if let card = provider.cards[safe: 0] {
                  InsightCardView(card: card, onTap: onTabooTap)
                      .accessibilityIdentifier("HomeInsightsCard_0")
              } else {
                  InsightPlaceholderCard(index: 0)
              }

              // 슬롯 1: 일진
              if let card = provider.cards[safe: 1] {
                  InsightCardView(card: card, onTap: onTodayTap)
                      .accessibilityIdentifier("HomeInsightsCard_1")
              } else {
                  InsightPlaceholderCard(index: 1)
              }

              // 슬롯 2: 실천
              if let card = provider.cards[safe: 2] {
                  InsightCardView(card: card, onTap: onPracticeTap)
                      .accessibilityIdentifier("HomeInsightsCard_2")
              } else {
                  InsightPlaceholderCard(index: 2)
              }
          }
          .padding(.horizontal, 16)
      }
  }
  .padding(.top, 16)
```

- `[safe: n]` 구현: `Collection`의 extension `subscript(safe index: Index) -> Element?`를  
  `Woontech/Shared/` 하위 `CollectionExtensions.swift`로 추가하거나 InsightCardView.swift 내부에 `private extension Array { subscript(safe i: Int) -> Element? { ... } }` 형태로 추가.

### Step 6 — HomeDashboardView 콘텐츠 교체
`HomeDashboardView.swift`의 `ScrollView` 내부:

```swift
// 기존 (삭제)
Text("준비중")
    .accessibilityIdentifier("HomeDashboardContentPlaceholder")

// 교체 (추가)
VStack(spacing: 0) {
    HeroInvestingCardView(
        provider: homeDeps.heroInvesting,
        userProfile: homeDeps.userProfile,
        onTap: { navigationPath.append(.investing) }
    )

    InsightsScrollView(
        provider: homeDeps.insights,
        onTabooTap:    { navigationPath.append(.tabooPlaceholder) },
        onTodayTap:    { navigationPath.append(.today) },
        onPracticeTap: { navigationPath.append(.practicePlaceholder) }
    )
}
.accessibilityIdentifier("HomeDashboardContent")
```

`Text("준비중")`의 `accessibilityIdentifier("HomeDashboardContentPlaceholder")`는 제거. 
기존 UI 테스트 T11–T25는 헤더와 네비게이션 관련이라 영향 없음.

### Step 7 — WoontechApp launch arg 파싱 (Hero mock 오버라이드)

`WoontechApp.init()` 내 `resolvedDeps` 구성 블록에서 추가 파싱:

```swift
// -mockHeroScore 120
let mockHeroScore: Int? = { ... args[idx+1] ... }()

// -mockHeroDisplayName 민수
let mockHeroDisplayName: String? = { ... }()

// -mockHeroDate 2026-01-01  (ISO-8601 yyyy-MM-dd)
let mockHeroDate: Date? = { ISO8601DateFormatter().date(from: ...) }()
```

위 값이 존재하면 `MockHeroInvestingProvider`/`MockUserProfileProvider`를 커스텀 값으로 초기화해 `HomeDependencies`에 주입.

### Step 8 — 단위 테스트 추가 (HomeDashboardTests.swift)

아래 §5 참조.

### Step 9 — UI 테스트 추가 (HomeDashboardUITests.swift)

아래 §6 참조.

---

## 5. Unit Test Plan

파일: `WoontechTests/Home/HomeDashboardTests.swift` (기존 파일에 추가)

> 단위 테스트는 SwiftUI 렌더링 없이 순수 로직을 검증한다.  
> Hero/Insights 카드 라우팅 검증은 `navigationPath` 변조가 SwiftUI 없이 불가하므로 UI 테스트로 위임.

| 테스트 함수 | 검증 AC | 내용 |
|------------|---------|------|
| `test_heroDate_jan1_2026_isThursday` | AC-2 | `DateFormatter(dateFormat:"yyyy.MM.dd EEEE", locale:ko_KR)` 로 `2026-01-01` 포맷 → `"2026.01.01 목요일"` |
| `test_heroDate_apr23_2026_isThursday` | AC-2 | Mock 기본 날짜 `2026-04-23` → `"2026.04.23 목요일"` |
| `test_heroScore_clamp_120_to_100` | AC-4 | `clampedScore(120)` == 100 |
| `test_heroScore_clamp_negative_to_0` | AC-4 | `clampedScore(-5)` == 0 |
| `test_heroScore_inRange_unchanged` | AC-4 | `clampedScore(72)` == 72 |
| `test_mockHeroInvesting_defaults` | AC-5 | `MockHeroInvestingProvider` 기본값: score==72, oneLiner=="공격보다 관찰이 내 성향에 맞아요" |
| `test_insightsCard_count_3` | AC-7 | `MockInsightsProvider().cards.count` == 3 |
| `test_insightsCard_slot0_isTaboo` | AC-7/8 | `cards[0].badgeLabel` == "금기" |
| `test_insightsCard_slot1_isToday` | AC-7/8 | `cards[1].badgeLabel` == "일진" |
| `test_insightsCard_slot2_isPractice` | AC-7/8 | `cards[2].badgeLabel` == "실천" |
| `test_insights_safeSubscript_outOfBounds` | AC-14 | `[InsightCard]()[safe: 0]` == nil (빈 배열 안전 접근) |
| `test_insights_2cardProvider_slot2_isNil` | AC-14 | 2개 카드 배열에서 `[safe: 2]` == nil → 뷰는 플레이스홀더 렌더 |

`clampedScore(_:)` 함수는 `HeroInvestingCardView.swift` 내부에서 `internal`(테스트 `@testable`로 접근)로 선언하거나, 별도 `HeroScoreHelper.swift`에 `func clampHeroScore(_ score: Int) -> Int` 로 추출 후 단위 테스트.

---

## 6. UI Test Plan

파일: `WoontechUITests/Home/HomeDashboardUITests.swift` (기존 파일에 추가)

> 아래 테스트는 구현자가 파일에 추가하지만 실행(pass)은 보장 범위 밖.

### T26: Hero 날짜 라벨 바인딩 (AC-2)
```
launchWithArgs(["-openHome", "-mockHeroDate", "2026-01-01"])
XCTAssertTrue(app.staticTexts["2026.01.01 목요일"].waitForExistence(timeout:3))
```
또는 `accessibilityIdentifier("HomeHeroDate")` 요소의 `.label` 검증.

### T27: 인사말 displayName 반영 (AC-3)
```
launchWithArgs(["-openHome", "-mockHeroDisplayName", "민수"])
XCTAssertTrue(app.staticTexts["HomeHeroGreeting"].waitForExistence(timeout:3))
XCTAssertEqual(app.staticTexts["HomeHeroGreeting"].label, "민수님, 오늘의 투자 태도예요")
```

### T28: Hero 카드 탭 → investing 라우트 (AC-6)
```
launchWithArgs(["-openHome"])
app.otherElements["HomeHeroCard"].tap()
XCTAssertTrue(app.staticTexts["HomeRoute_investingDest"].waitForExistence(timeout:3))
```

### T29: 금기 카드 탭 → tabooPlaceholder 라우트 (AC-9)
```
launchWithArgs(["-openHome"])
app.otherElements["HomeInsightsCard_0"].tap()
XCTAssertTrue(app.staticTexts["HomeRoute_tabooDest"].waitForExistence(timeout:3))
```

### T30: 일진 카드 탭 → today 라우트 (AC-10)
```
launchWithArgs(["-openHome"])
app.otherElements["HomeInsightsCard_1"].tap()
XCTAssertTrue(app.staticTexts["HomeRoute_todayDest"].waitForExistence(timeout:3))
```

### T31: 실천 카드 탭 → practicePlaceholder 라우트 (AC-11)
```
launchWithArgs(["-openHome"])
app.otherElements["HomeInsightsCard_2"].tap()
XCTAssertTrue(app.staticTexts["HomeRoute_practiceDest"].waitForExistence(timeout:3))
```

### T32: Dynamic Type XL — Hero score·oneLiner 잘림 없음 (AC-12)
```
app.launchEnvironment["UIContentSizeCategoryOverride"] = "UICTContentSizeCategoryAccessibilityL"
launchWithArgs(["-openHome"])
let score = app.staticTexts["HomeHeroScore"]
let oneLiner = app.staticTexts.matching(identifier: "HomeHeroOneLiner").firstMatch
XCTAssertTrue(score.waitForExistence(timeout:3))
XCTAssertTrue(oneLiner.exists)
// 잘림 없음 검증: 요소가 존재하고 frame.height > 0
XCTAssertGreaterThan(score.frame.height, 0)
XCTAssertGreaterThan(oneLiner.frame.height, 0)
```

### T33: Insights 가로 스크롤 — 3번째 카드 접근 가능 (AC-13)
```
launchWithArgs(["-openHome"])
// 첫 번째 카드가 보임
XCTAssertTrue(app.otherElements["HomeInsightsCard_0"].waitForExistence(timeout:3))
// 좌로 스와이프하여 3번째 카드 확인
let scrollView = app.scrollViews.firstMatch
scrollView.swipeLeft()
XCTAssertTrue(app.otherElements["HomeInsightsCard_2"].waitForExistence(timeout:3))
// 혹은 staticTexts "오늘의 실천" 가시성 확인
XCTAssertTrue(app.staticTexts["오늘의 실천"].exists)
```

---

## 7. Risks / Open Questions

1. **InsightCard에 SwiftUI.Color 직접 사용**  
   `InsightsProviding.swift`에 `import SwiftUI` 추가 필요. 기존 Provider 파일은 `import Foundation`만 사용. 대안은 `BadgeColorToken` enum을 정의하고 뷰 레이어에서 Color로 변환하는 방식인데, 코드 복잡도 증가. → **채택안**: SwiftUI import 허용 (프로젝트가 SwiftUI 전용이므로 문제 없음).

2. **`[safe:]` subscript 위치**  
   `Array`(또는 `Collection`) extension을 shared 레이어에 두면 다른 피처에서도 재사용 가능. 단, 별도 파일 추가 시 Xcode 프로젝트 파일(`.xcodeproj`)에 멤버 등록이 필요함에 주의.

3. **날짜 포맷 로케일 의존**  
   포맷터 `locale = Locale(identifier: "ko_KR")` 고정으로 디바이스 설정과 무관하게 한국어 요일 출력. 테스트 환경(시뮬레이터 로케일)이 달라도 테스트가 통과해야 하므로 포맷터 생성 시 `locale`을 명시적으로 고정.

4. **Hero 카드 단일 hit-test 보장**  
   `Button` 내부에 인터랙티브 뷰가 없으면 자동으로 카드 전체가 단일 탭 영역. 단, 나중에 자식 뷰 추가 시 `.allowsHitTesting(false)` 누락으로 깨질 위험. → 카드 내부 모든 뷰에 `.allowsHitTesting(false)` 명시 또는 구조 문서화.

5. **UI 테스트의 `UIContentSizeCategoryOverride` 지원 범위**  
   iOS 17+ 시뮬레이터에서 `launchEnvironment` 키를 통한 Dynamic Type 오버라이드가 동작하는지 사전 확인 필요. 대안: `app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"]`.

6. **AC-14 PlaceholderCard 디자인**  
   빈 슬롯의 시각적 처리(빈 회색 박스)는 spec에 정의되지 않음. 단순 `RoundedRectangle(fill: DesignTokens.gray).frame(width:160)` 수준으로 구현하되 추후 디자이너 리뷰 대상.

7. **`HomeDashboardContentPlaceholder` 제거 영향**  
   기존 `accessibilityIdentifier("HomeDashboardContentPlaceholder")`가 제거되는데, WoontechUITests 파일에 이를 참조하는 테스트가 없는지 grep으로 확인 후 제거.  
   (현재 확인 결과: `HomeDashboardUITests.swift`와 `HomeDashboardTests.swift` 모두 해당 identifier를 사용하지 않음 — 안전하게 제거 가능.)
