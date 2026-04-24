# implement-plan.md — WF3-01 홈 대시보드 Shell + Header + DI 스캐폴드 (v2)

---

## 1. Goal

WF2 사주 입력 완료 후 사용자가 랜딩하는 홈 탭(WF3)의 기반 구조를 구축한다.  
`HomePlaceholderView`를 삭제하고, **DI 프로토콜 5종 + Mock 구현체 + `HomeDependencies`** 를 도입하며, `HomeDashboardView`(NavigationStack 내장 + Section 0 Header)로 교체한다.

---

## 2. Affected Files

### New Files

| 경로 | 설명 |
|------|------|
| `ios/Woontech/Features/Home/Providers/UserProfileProviding.swift` | `UserProfileProviding` 프로토콜 + `MockUserProfileProvider` |
| `ios/Woontech/Features/Home/Providers/NotificationCenterProviding.swift` | `NotificationCenterProviding` 프로토콜 + `MockNotificationCenterProvider` |
| `ios/Woontech/Features/Home/Providers/HeroInvestingProviding.swift` | `HeroInvestingProviding` 프로토콜 (시그니처만) + `MockHeroInvestingProvider` |
| `ios/Woontech/Features/Home/Providers/InsightsProviding.swift` | `InsightsProviding` 프로토콜 (시그니처만) + `MockInsightsProvider` |
| `ios/Woontech/Features/Home/Providers/WeeklyEventsProviding.swift` | `WeeklyEventsProviding` 프로토콜 (시그니처만) + `MockWeeklyEventsProvider` |
| `ios/Woontech/Features/Home/HomeDependencies.swift` | `HomeDependencies` ObservableObject 클래스 (5개 provider 필드 집합) |
| `ios/Woontech/Features/Home/HomeRoute.swift` | `HomeRoute` Hashable enum (5 케이스) + `WeeklyEvent` stub struct |
| `ios/Woontech/Features/Home/HomeDashboardView.swift` | 홈 대시보드 메인 컨테이너 (NavigationStack 내장, `HomeTabBarPlaceholderView` private struct 포함) |
| `ios/Woontech/Features/Home/HomeHeaderView.swift` | Section 0 Header (wordmark, 벨+배지, 아바타) |
| `ios/Woontech/Features/Home/HomeRouteDestinations.swift` | 5개 라우트 목적지 "준비중" placeholder 뷰 |
| `ios/WoontechTests/Home/HomeDashboardTests.swift` | 배지 로직 · provider 주입 unit 테스트 |
| `ios/WoontechUITests/Home/HomeDashboardUITests.swift` | 홈 UI/접근성 테스트 |

### Modified Files

| 경로 | 변경 내용 |
|------|-----------|
| `ios/Woontech/App/RootView.swift` | `.home` 케이스에서 `HomePlaceholderView` → `HomeDashboardView` 교체; `.environmentObject(homeDependencies)` 추가 |
| `ios/Woontech/App/WoontechApp.swift` | `@StateObject var homeDependencies: HomeDependencies` 생성·주입; `-mockHomeUnreadCount`, `-mockHomeAvatarInitial` launch args 처리 |
| `ios/Woontech/Shared/DesignTokens.swift` | 홈 Header 하단 구분선 색(`headerBorder`) 및 아바타 배경색(`avatarBg`) 토큰 추가 (필요 시) |

### Deleted Files

| 경로 | 이유 |
|------|------|
| `ios/Woontech/Features/Home/HomePlaceholderView.swift` | `HomeDashboardView`로 대체. 참조 제거 후 파일 삭제 |

---

## 3. Data Model / State Changes

### 3-1. WeeklyEvent (stub)

```
struct WeeklyEvent: Hashable, Identifiable {
    let id: UUID          // 기본값 UUID()
    // WF3-03에서 실제 필드 추가
}
```

### 3-2. HomeRoute

```
enum HomeRoute: Hashable {
    case investing
    case event(WeeklyEvent)
    case today
    case tabooPlaceholder
    case practicePlaceholder
}
```

`WeeklyEvent`이 `Hashable`이므로 `event(_:)` 케이스도 자동으로 `Hashable` 충족.

### 3-3. 5개 DI 프로토콜

```
protocol UserProfileProviding {
    var displayName: String { get }
    var avatarInitial: String { get }
}

protocol NotificationCenterProviding {
    var unreadCount: Int { get }
}

protocol HeroInvestingProviding {
    // WF3-02에서 선언 확장
}

protocol InsightsProviding {
    // WF3-02에서 선언 확장
}

protocol WeeklyEventsProviding {
    // WF3-03에서 선언 확장
}
```

각 파일에 대응하는 Mock 구현체(기본값: displayName="홍길동", avatarInitial="홍", unreadCount=2) 포함.

### 3-4. HomeDependencies

```
final class HomeDependencies: ObservableObject {
    var userProfile: any UserProfileProviding
    var notificationCenter: any NotificationCenterProviding
    var heroInvesting: any HeroInvestingProviding
    var insights: any InsightsProviding
    var weeklyEvents: any WeeklyEventsProviding

    static let mock = HomeDependencies(...)  // 기본 Mock 조합
}
```

- `WoontechApp`에서 `@StateObject` 생성 → `RootView`에 `.environmentObject(homeDependencies)` 전달.
- `RootView.home` 케이스는 `HomeDashboardView`에 `.environmentObject(homeDependencies)` 부여.

### 3-5. WoontechApp 추가 launch-arg 처리

| 인자 | 효과 |
|------|------|
| `-mockHomeUnreadCount <Int>` | `homeDependencies.notificationCenter` 의 `unreadCount` 덮어쓰기 (UI 테스트용 Mock 교체) |
| `-mockHomeAvatarInitial <String>` | `homeDependencies.userProfile` 의 `avatarInitial` 덮어쓰기 |

이 두 인자가 없으면 `HomeDependencies.mock` 기본값 사용.

---

## 4. Implementation Steps

각 단계는 독립 컴파일 가능 단위. 이전 단계가 완료된 후 다음 단계 진행.

### Step 1 — WeeklyEvent 스텁 + HomeRoute 선언

- `HomeRoute.swift` 파일 생성.
- `WeeklyEvent` struct 정의 (id: UUID, Hashable, Identifiable).
- `HomeRoute` enum 정의 (5 케이스). 컴파일 확인.

### Step 2 — DI 프로토콜 5개 선언

- `Providers/` 폴더 하위에 각 파일 생성.
- 프로토콜 본문은 WF3-01 범위 내에서만 선언; `HeroInvestingProviding`, `InsightsProviding`, `WeeklyEventsProviding`은 빈 프로토콜로.
- 각 파일에 Mock 구현체 함께 작성. 컴파일 확인.

### Step 3 — HomeDependencies 생성

- `HomeDependencies.swift` 생성.
- `final class HomeDependencies: ObservableObject` 선언; 5개 `any Protocol` 필드.
- `init` 기본 인자에 Mock 인스턴스 사용.
- `static let mock` 편의 프로퍼티 제공.
- 컴파일 확인.

### Step 4 — 라우트 목적지 placeholder 뷰 생성

- `HomeRouteDestinations.swift` 생성.
- `InvestingPlaceholderView`, `EventPlaceholderView`, `TodayPlaceholderView`, `TabooPlaceholderView`, `PracticePlaceholderView` 5개 뷰 선언.
- 각 뷰: `Text("준비중")` + `.accessibilityIdentifier("HomeRoute_<name>Dest")`.
- 컴파일 확인.

### Step 5 — DesignTokens 홈 토큰 추가

- `DesignTokens.swift`에 `static let headerBorder` (구분선, line3 재사용 또는 신규), `static let avatarBg` (아바타 원형 배경, gray 재사용 또는 신규) 추가.
- 실질 색상은 기존 gray/#F2F2F2 재사용해도 무방. 신규 semantic alias 추가 권장.

### Step 6 — HomeHeaderView 구현

- `HomeHeaderView.swift` 생성.
- 인터페이스:
  ```swift
  struct HomeHeaderView: View {
      let userProfile: any UserProfileProviding
      let notificationCenter: any NotificationCenterProviding
      var onBellTap: () -> Void = {}
      var onAvatarTap: () -> Void = {}
  }
  ```
- 레이아웃: `HStack` (spacing: 0)
  - 좌: `Text("운테크")` — bold, ink 색, `.accessibilityIdentifier("HomeWordmark")`
  - Spacer
  - 우: 벨 버튼 + 배지 오버레이 + 아바타 원형 버튼
- **배지 로직**:
  - `unreadCount == 0` → 배지 뷰 hidden
  - `1...99` → 정수 문자열 표시
  - `≥ 100` → "99+" 표시
  - 배지 로직을 파일-내부 순수 함수 `badgeLabel(for count: Int) -> String?` 로 추출 (unit test 대상)
- **접근성**:
  - 벨 버튼: `.accessibilityLabel("알림 \(unreadCount)개")`, `.accessibilityIdentifier("HomeBellButton")`
  - 배지: `.accessibilityIdentifier("HomeBellBadge")`
  - 아바타 버튼: `.accessibilityLabel("프로필 \(userProfile.displayName)")`, `.accessibilityIdentifier("HomeAvatarButton")`
- Dynamic Type 대응: `minimumScaleFactor` + `.lineLimit(1)` 적용.
- 컴파일 + Preview 확인.

### Step 7 — HomeDashboardView 구현

- `HomeDashboardView.swift` 생성.
- `@EnvironmentObject var homeDeps: HomeDependencies`.
- `@State private var navigationPath: [HomeRoute] = []`.
- **테스트 스파이 카운터** (AC-6/AC-7): 탭 핸들러 호출 횟수를 접근성 트리로 노출:
  - `@State private var bellTapCount = 0`
  - `@State private var avatarTapCount = 0`
- 레이아웃:
  ```
  VStack(spacing: 0) {
      HomeHeaderView(
          userProfile: homeDeps.userProfile,
          notificationCenter: homeDeps.notificationCenter,
          onBellTap: { bellTapCount += 1 },
          onAvatarTap: { avatarTapCount += 1 }
      )
      Divider()  // or custom line using DesignTokens.headerBorder
      NavigationStack(path: $navigationPath) {
          ScrollView {
              Text("준비중")
                  .accessibilityIdentifier("HomeDashboardContentPlaceholder")
          }
          .navigationBarHidden(true)
          .navigationDestination(for: HomeRoute.self) { route in
              // switch → 각 placeholder 뷰
          }
      }
      // TabBar placeholder (private struct 아래 정의)
      HomeTabBarPlaceholderView()
          .accessibilityIdentifier("HomeTabBarPlaceholder")
  }
  .accessibilityIdentifier("HomeDashboardRoot")
  // 스파이 카운터 노출 (opacity 0이지만 접근성 트리에 남아 UI 테스트에서 읽힘)
  .overlay(alignment: .topLeading) {
      VStack {
          Text("\(bellTapCount)")
              .accessibilityIdentifier("HomeBellTapCount")
          Text("\(avatarTapCount)")
              .accessibilityIdentifier("HomeAvatarTapCount")
      }
      .opacity(0)
      .allowsHitTesting(false)
  }
  ```
- **숨겨진 push 트리거 버튼** (UI 테스트 AC-10용): 각 라우트당 `.opacity(0)` 버튼 + accessibilityIdentifier
  - "HomeNavPushInvesting", "HomeNavPushEvent", "HomeNavPushToday", "HomeNavPushTaboo", "HomeNavPushPractice"
  - 버튼 탭 시 `navigationPath.append(...)`.
- **`HomeTabBarPlaceholderView`** — 같은 파일 하단에 `private struct`로 선언:
  ```swift
  private struct HomeTabBarPlaceholderView: View {
      var body: some View {
          Rectangle()
              .fill(Color(.systemBackground))
              .frame(height: 49)
              .overlay(alignment: .top) { Divider() }
      }
  }
  ```
- 컴파일 + Preview 확인.

### Step 8 — RootView 수정

- `.home` case에서 `HomePlaceholderView` → `HomeDashboardView` 교체.
- `.environmentObject(homeDeps)` 주입 추가.
- 기존 `onOpenReferral` 콜백은 WF3-01 범위에서는 제거 (HomeDashboardView가 자체 처리하지 않음). 단, 추후 탭바 연동을 위해 RootView 수준 콜백은 보존 가능 — 이번 슬라이스에서는 HomeDashboardView에 전달하지 않아도 됨.
- 컴파일 확인.

### Step 9 — WoontechApp 수정

- `@StateObject private var homeDeps: HomeDependencies` 추가.
- `init()` 내부에서 launch args 파싱:
  - `-mockHomeUnreadCount <Int>` 검출 시 커스텀 Mock 생성
  - `-mockHomeAvatarInitial <String>` 검출 시 커스텀 Mock 생성
  - 인자 없으면 `HomeDependencies.mock` 사용
- `WindowGroup` body에서 `.environmentObject(homeDeps)` 추가.
- 기존 `-openHome` 흐름은 변경 없음 (RootView.applyLaunchArgs가 route = .home 설정).
- 컴파일 확인.

### Step 10 — HomePlaceholderView 삭제

- Xcode 프로젝트에서 `HomePlaceholderView.swift` 제거.
- 남은 참조(localization key `saju.home.*`) 존재 여부 확인 후 정리.
- 컴파일 확인.

### Step 11 — Unit 테스트 작성

`WoontechTests/Home/HomeDashboardTests.swift` 작성 (상세는 섹션 5 참조).

### Step 12 — UI 테스트 작성

`WoontechUITests/Home/HomeDashboardUITests.swift` 작성 (상세는 섹션 6 참조).

---

## 5. Unit Test Plan

파일: `WoontechTests/Home/HomeDashboardTests.swift`

| 테스트 ID | 대상 AC | 테스트 내용 |
|-----------|---------|-------------|
| `test_badgeLabel_zeroCount_returnsNil` | AC-3 | `badgeLabel(for: 0) == nil` |
| `test_badgeLabel_oneCount_returnsOne` | AC-3 | `badgeLabel(for: 1) == "1"` |
| `test_badgeLabel_99_returns99` | AC-3 | `badgeLabel(for: 99) == "99"` |
| `test_badgeLabel_100_returns99Plus` | AC-4 | `badgeLabel(for: 100) == "99+"` |
| `test_badgeLabel_150_returns99Plus` | AC-4 | `badgeLabel(for: 150) == "99+"` |
| `test_mockUserProfile_defaultInitial` | AC-5 | `MockUserProfileProvider().avatarInitial == "홍"` |
| `test_homeDependencies_mock_compilesAndDefaultValues` | AC-8 | `HomeDependencies.mock` 생성, 5개 필드 non-nil 확인 |
| `test_homeDependencies_customMockReplace_compiles` | AC-8 | `HomeDependencies`에 커스텀 Mock struct 주입 가능, 컴파일 확인 |
| `test_homeRoute_allCasesHashable` | AC-9 | 5개 케이스를 `Set<HomeRoute>`에 삽입, count == 5 |
| `test_homeRoute_event_hashEquality` | AC-9 | 동일 id의 `WeeklyEvent`를 가진 `.event(_:)` 두 케이스가 `==` |

> `badgeLabel(for:)` 함수는 `HomeHeaderView.swift` 내부 `internal` 또는 별도 `HomeHeaderBadgeHelper.swift` (internal) 에 위치시켜 `@testable import Woontech`로 접근.

---

## 6. UI Test Plan

파일: `WoontechUITests/Home/HomeDashboardUITests.swift`

모든 테스트는 `app.launchArguments = ["-openHome"]` (+ 추가 mock args)로 시작. Splash wait 후 `HomeDashboardRoot` 존재 확인.

| 테스트 ID | 대상 AC | 시나리오 | 검증 방법 |
|-----------|---------|---------|-----------|
| `test_homeDashboard_wordmarkVisible` | AC-1, AC-2 | `-openHome` 진입 | `staticTexts["운테크"].exists` |
| `test_homeDashboard_rendersNotPlaceholder` | AC-1 | `-openHome` 진입 | `HomeDashboardRoot` 존재, `HomeRoot`(구 placeholder ID) 미존재 |
| `test_bellBadge_hiddenWhenZero` | AC-3 | `-openHome -mockHomeUnreadCount 0` | `HomeBellBadge` 미존재 또는 hidden |
| `test_bellBadge_showsCount_whenPositive` | AC-3 | `-openHome -mockHomeUnreadCount 2` | `HomeBellBadge` staticText == "2" |
| `test_bellBadge_99Plus_when150` | AC-4 | `-openHome -mockHomeUnreadCount 150` | `HomeBellBadge` staticText == "99+" |
| `test_avatarInitial_shownFromMock` | AC-5 | `-openHome -mockHomeAvatarInitial 민` | `HomeAvatarButton` 내 `staticTexts["민"].exists` |
| `test_bellTap_handlerCalledOnce` | AC-6 | `-openHome` → `HomeBellButton` 1회 tap | `staticTexts["HomeBellTapCount"].label == "1"` (스파이 카운터 검증) |
| `test_avatarTap_handlerCalledOnce` | AC-7 | `-openHome` → `HomeAvatarButton` 1회 tap | `staticTexts["HomeAvatarTapCount"].label == "1"` (스파이 카운터 검증) |
| `test_navPush_investing_showsPlaceholder` | AC-10 | `HomeNavPushInvesting` 버튼 tap | `HomeRoute_investingDest` 뷰 존재 |
| `test_navPush_event_showsPlaceholder` | AC-10 | `HomeNavPushEvent` 버튼 tap | `HomeRoute_eventDest` 뷰 존재 |
| `test_navPush_today_showsPlaceholder` | AC-10 | `HomeNavPushToday` 버튼 tap | `HomeRoute_todayDest` 뷰 존재 |
| `test_navPush_taboo_showsPlaceholder` | AC-10 | `HomeNavPushTaboo` 버튼 tap | `HomeRoute_tabooDest` 뷰 존재 |
| `test_navPush_practice_showsPlaceholder` | AC-10 | `HomeNavPushPractice` 버튼 tap | `HomeRoute_practiceDest` 뷰 존재 |
| `test_dynamicType_xl_noOverlap` | AC-11 | `-openHome` + Dynamic Type XL (preferredContentSizeCategory 설정) | `HomeWordmark`·`HomeBellButton`·`HomeAvatarButton` frame이 서로 겹치지 않음 |
| `test_voiceOver_bellLabel_unread2` | AC-12 | `-openHome` (기본 unreadCount=2) | `HomeBellButton.label == "알림 2개"` |

> **스파이 카운터 패턴**: `HomeDashboardView`는 `@State` 정수 카운터(`bellTapCount`, `avatarTapCount`)를 유지하고, 핸들러 호출 시 각각 +1한다. 카운터 값은 `.opacity(0)` overlay의 `Text` 뷰를 통해 접근성 트리에 노출되므로, UI 테스트에서 `staticTexts["HomeBellTapCount"].label` 등을 읽어 호출 횟수를 정확히 검증할 수 있다. 이 방식은 외부 라이브러리 없이 "1회 호출" 요건을 충족한다.

---

## 7. Risks / Open Questions

| # | 위험/질문 | 권고 |
|---|-----------|------|
| R1 | `any Protocol` 필드를 가진 `ObservableObject`는 프로토콜 변경 시 뷰가 자동 re-render되지 않음. WF3-02/03에서 실시간 데이터 반영 필요 시 별도 `@Published` 래퍼 또는 Combine 연동 필요 | WF3-01 범위 내 static mock이므로 당장 문제 없음. WF3-02 진입 전 설계 확정 |
| R2 | `HomeDashboardView` 내 NavigationStack이 VStack 중간에 있으면, iOS 17에서 `navigationDestination` 적용 시 화면 전체를 덮는 push가 의도대로 동작하는지 확인 필요 | Step 7 구현 후 시뮬레이터에서 직접 검증 필요 |
| R3 | `HomeHeaderView`에서 Dynamic Type XL 적용 시 "운테크" 텍스트와 아이콘들이 가로 공간 부족으로 겹칠 수 있음 | `minimumScaleFactor(0.7)` + `lineLimit(1)` 적용, Spacer 제거 후 최소 간격 보장하는 레이아웃 설계 |
| R4 | `-mockHomeUnreadCount`, `-mockHomeAvatarInitial` launch arg는 신규 패턴. `WoontechApp.init()`에서 `HomeDependencies` 초기화 시 적용 순서 주의 필요 | `init()` 맨 마지막에 `homeDeps` 생성, args 파싱 결과 반영 |
| R5 | `HomePlaceholderView.swift` 삭제 시 localization 키(`saju.home.*`)가 다른 곳에 재사용되고 있는지 확인 필요 | 삭제 전 Grep으로 전체 참조 확인 |
| R6 | `WeeklyEvent`의 위치: `HomeRoute.swift` 내 정의 vs 별도 `Models/WeeklyEvent.swift` | WF3-03에서 실제 필드 대규모 추가 예정이므로 `HomeRoute.swift` 내 스텁으로 두고 WF3-03에서 별도 파일로 이동 권장 |
| R7 | 벨 아이콘이 SVG라고 spec에 명시되어 있으나 `Assets.xcassets`에 해당 에셋이 있는지 미확인 | 구현 전 `Assets.xcassets` 확인. 없으면 SF Symbols (`bell` 또는 `bell.badge`) 임시 대체 |
