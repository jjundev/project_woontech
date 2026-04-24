# Implementation Checklist — WF3-01 홈 대시보드 Shell + Header + DI 스캐폴드

---

## Requirements (from spec)

- [ ] R1: `RootView.Route.home` 케이스가 `HomeDashboardView`를 렌더한다. `HomePlaceholderView`는 더 이상 참조되지 않는다.
- [ ] R2: `HomeDashboardView`는 상단 고정 Header + 하단 고정 TabBar placeholder + 가운데 빈 ScrollView("준비중") 슬롯으로 구성된다.
- [ ] R3: `HomeDashboardView` 내부에 `NavigationStack`이 포함되어 있다.
- [ ] R4: Header 좌측에 "운테크" wordmark가 고정 표시된다.
- [ ] R5: Header 우측에 알림 벨 SVG/아이콘 + unread count 배지가 있다. 카운트 0이면 배지 숨김, ≥100이면 "99+".
- [ ] R6: Header 우측에 프로필 아바타 원형(`displayName` 첫 글자) 버튼이 있다.
- [ ] R7: 벨 탭 → `onBellTap` 핸들러 호출.
- [ ] R8: 아바타 탭 → `onAvatarTap` 핸들러 호출.
- [ ] R9: `UserProfileProviding` 프로토콜 선언 (`displayName: String`, `avatarInitial: String`) + `MockUserProfileProvider` (기본값: displayName="홍길동", avatarInitial="홍").
- [ ] R10: `NotificationCenterProviding` 프로토콜 선언 (`unreadCount: Int`) + `MockNotificationCenterProvider` (기본값: unreadCount=2).
- [ ] R11: `HeroInvestingProviding` 빈 프로토콜 선언 + `MockHeroInvestingProvider`.
- [ ] R12: `InsightsProviding` 빈 프로토콜 선언 + `MockInsightsProvider`.
- [ ] R13: `WeeklyEventsProviding` 빈 프로토콜 선언 + `MockWeeklyEventsProvider`.
- [ ] R14: `HomeDependencies` (ObservableObject) — 5개 providing 필드를 모아 `HomeDashboardView`에 `@EnvironmentObject`로 전달.
- [ ] R15: `HomeRoute` Hashable enum 5케이스: `investing`, `event(WeeklyEvent)`, `today`, `tabooPlaceholder`, `practicePlaceholder`.
- [ ] R16: 각 라우트 목적지 View가 "준비중" placeholder로 존재.
- [ ] R17: 런치 인자 `-openHome`으로 홈 진입 시 기본 `MockHomeDependencies` 주입됨.
- [ ] R18: VoiceOver — 벨 버튼 레이블 "알림 {count}개", 아바타 버튼 레이블 "프로필 {displayName}".
- [ ] R19: Dynamic Type Large까지 Header 요소 잘림/겹침 없음.
- [ ] R20: `DesignTokens.swift`에 `headerBorder`, `avatarBg` 토큰 추가 (필요 시).

---

## Implementation Steps

- [ ] S1: `HomeRoute.swift` 생성 — `WeeklyEvent` stub struct (id: UUID, Hashable, Identifiable) + `HomeRoute` enum 5케이스 정의.
- [ ] S2: `Providers/` 하위 5개 파일 생성 — 각 DI 프로토콜 + Mock 구현체 작성. `HeroInvestingProviding`, `InsightsProviding`, `WeeklyEventsProviding`은 빈 프로토콜. 컴파일 확인.
- [ ] S3: `HomeDependencies.swift` 생성 — `final class HomeDependencies: ObservableObject`, 5개 `any Protocol` 필드, `static let mock` 편의 프로퍼티. 컴파일 확인.
- [ ] S4: `HomeRouteDestinations.swift` 생성 — 5개 placeholder 뷰 (`InvestingPlaceholderView` 등), 각 뷰에 `Text("준비중")` + `.accessibilityIdentifier("HomeRoute_<name>Dest")`.
- [ ] S5: `DesignTokens.swift` 수정 — `headerBorder`, `avatarBg` semantic 토큰 추가.
- [ ] S6: `HomeHeaderView.swift` 생성 — `HStack` 레이아웃 (wordmark / Spacer / 벨+배지 / 아바타). 배지 로직 `badgeLabel(for count: Int) -> String?` 내부 함수로 추출. VoiceOver 레이블, accessibilityIdentifiers(`HomeWordmark`, `HomeBellButton`, `HomeBellBadge`, `HomeAvatarButton`), `minimumScaleFactor` + `lineLimit(1)` Dynamic Type 대응.
- [ ] S7: `HomeDashboardView.swift` 생성 — `@EnvironmentObject var homeDeps: HomeDependencies`, `@State navigationPath: [HomeRoute]`, `@State bellTapCount`, `@State avatarTapCount` spy 카운터. `HomeHeaderView` + Divider + `NavigationStack(path:)` + `navigationDestination` + `HomeTabBarPlaceholderView`. 숨겨진 push 트리거 버튼 5개(`HomeNavPushInvesting` 등 `.opacity(0)`). Spy 카운터 `.opacity(0)` overlay 노출(`HomeBellTapCount`, `HomeAvatarTapCount`). `private struct HomeTabBarPlaceholderView` 파일 하단 정의 (height 49).
- [ ] S8: `RootView.swift` 수정 — `.home` 케이스에서 `HomePlaceholderView` → `HomeDashboardView` + `.environmentObject(homeDeps)` 교체.
- [ ] S9: `WoontechApp.swift` 수정 — `@StateObject private var homeDeps: HomeDependencies` 추가. `init()` 내 launch args 파싱(`-mockHomeUnreadCount`, `-mockHomeAvatarInitial`). `WindowGroup` body에 `.environmentObject(homeDeps)` 추가.
- [ ] S10: `HomePlaceholderView.swift` 삭제 — 삭제 전 전체 참조 및 localization key(`saju.home.*`) 확인 후 제거. 컴파일 확인.
- [ ] S11: Unit 테스트 작성 (`WoontechTests/Home/HomeDashboardTests.swift`).
- [ ] S12: UI 테스트 작성 (`WoontechUITests/Home/HomeDashboardUITests.swift`).

---

## Tests

### Unit Tests (`WoontechTests/Home/HomeDashboardTests.swift`)

- [ ] T1 (unit): `test_badgeLabel_zeroCount_returnsNil` — `badgeLabel(for: 0) == nil` (AC-3)
- [ ] T2 (unit): `test_badgeLabel_oneCount_returnsOne` — `badgeLabel(for: 1) == "1"` (AC-3)
- [ ] T3 (unit): `test_badgeLabel_99_returns99` — `badgeLabel(for: 99) == "99"` (AC-3)
- [ ] T4 (unit): `test_badgeLabel_100_returns99Plus` — `badgeLabel(for: 100) == "99+"` (AC-4)
- [ ] T5 (unit): `test_badgeLabel_150_returns99Plus` — `badgeLabel(for: 150) == "99+"` (AC-4)
- [ ] T6 (unit): `test_mockUserProfile_defaultInitial` — `MockUserProfileProvider().avatarInitial == "홍"` (AC-5)
- [ ] T7 (unit): `test_homeDependencies_mock_compilesAndDefaultValues` — `HomeDependencies.mock` 생성, 5개 필드 non-nil (AC-8)
- [ ] T8 (unit): `test_homeDependencies_customMockReplace_compiles` — 커스텀 Mock struct 교체 주입, 컴파일 확인 (AC-8)
- [ ] T9 (unit): `test_homeRoute_allCasesHashable` — 5케이스 `Set<HomeRoute>` 삽입 후 count == 5 (AC-9)
- [ ] T10 (unit): `test_homeRoute_event_hashEquality` — 동일 id `WeeklyEvent`의 `.event(_:)` 두 인스턴스가 `==` (AC-9)

### UI Tests (`WoontechUITests/Home/HomeDashboardUITests.swift`)

모든 테스트는 `app.launchArguments = ["-openHome"]` (+ 추가 mock args)로 시작.

- [ ] T11 (ui): `test_homeDashboard_wordmarkVisible` — `staticTexts["운테크"].exists` (AC-1, AC-2)
- [ ] T12 (ui): `test_homeDashboard_rendersNotPlaceholder` — `HomeDashboardRoot` 존재, 구 placeholder ID 미존재 (AC-1)
- [ ] T13 (ui): `test_bellBadge_hiddenWhenZero` — `-mockHomeUnreadCount 0` → `HomeBellBadge` 미존재 또는 hidden (AC-3)
- [ ] T14 (ui): `test_bellBadge_showsCount_whenPositive` — `-mockHomeUnreadCount 2` → `HomeBellBadge` label == "2" (AC-3)
- [ ] T15 (ui): `test_bellBadge_99Plus_when150` — `-mockHomeUnreadCount 150` → `HomeBellBadge` label == "99+" (AC-4)
- [ ] T16 (ui): `test_avatarInitial_shownFromMock` — `-mockHomeAvatarInitial 민` → `HomeAvatarButton` 내 `staticTexts["민"].exists` (AC-5)
- [ ] T17 (ui): `test_bellTap_handlerCalledOnce` — `HomeBellButton` 1회 tap → `staticTexts["HomeBellTapCount"].label == "1"` (AC-6)
- [ ] T18 (ui): `test_avatarTap_handlerCalledOnce` — `HomeAvatarButton` 1회 tap → `staticTexts["HomeAvatarTapCount"].label == "1"` (AC-7)
- [ ] T19 (ui): `test_navPush_investing_showsPlaceholder` — `HomeNavPushInvesting` tap → `HomeRoute_investingDest` 존재 (AC-10)
- [ ] T20 (ui): `test_navPush_event_showsPlaceholder` — `HomeNavPushEvent` tap → `HomeRoute_eventDest` 존재 (AC-10)
- [ ] T21 (ui): `test_navPush_today_showsPlaceholder` — `HomeNavPushToday` tap → `HomeRoute_todayDest` 존재 (AC-10)
- [ ] T22 (ui): `test_navPush_taboo_showsPlaceholder` — `HomeNavPushTaboo` tap → `HomeRoute_tabooDest` 존재 (AC-10)
- [ ] T23 (ui): `test_navPush_practice_showsPlaceholder` — `HomeNavPushPractice` tap → `HomeRoute_practiceDest` 존재 (AC-10)
- [ ] T24 (ui): `test_dynamicType_xl_noOverlap` — Dynamic Type XL에서 `HomeWordmark`·`HomeBellButton`·`HomeAvatarButton` frame 겹침 없음 (AC-11)
- [ ] T25 (ui): `test_voiceOver_bellLabel_unread2` — 기본 mock (unreadCount=2) 진입 후 `HomeBellButton.label == "알림 2개"` (AC-12)
