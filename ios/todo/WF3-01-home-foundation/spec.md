# WF3-01 — 홈 대시보드 Shell + Header + DI 스캐폴드

## User story / motivation

WF2 사주 입력 완료 후 사용자가 landing하는 홈 탭(WF3)의 **기반 구조**를 구축한다.
이후 슬라이스(02~06)가 올라탈 `HomeDashboardView` 컨테이너, NavigationStack 라우팅,
DI 컨테이너(프로토콜 5종 + mock 구현체), 그리고 가장 단순한 **Section 0 Header**(알림
벨/아바타)까지를 하나의 테스트 가능한 단위로 묶는다. 현재 `RootView`의
`HomePlaceholderView`는 이 단계에서 `HomeDashboardView`로 교체된다.

## Functional requirements

- `RootView.Route.home` 케이스가 `HomeDashboardView`를 렌더 (기존 `HomePlaceholderView` 제거).
- `HomeDashboardView`는 상단 고정 **Header** + 하단 고정 **TabBar 자리(placeholder 시각)** +
  가운데 컨텐츠 슬롯으로 구성. 컨텐츠 슬롯은 02~03 슬라이스에서 채움 (이번 단계에서는 빈
  `ScrollView` + "준비중" placeholder).
- `HomeDashboardView` 내부에 **NavigationStack**이 포함되어, 이후 슬라이스에서 push되는
  detail 라우트(`investing`, `event`, `today`, `tabooPlaceholder`, `practicePlaceholder`)를
  수용할 수 있어야 한다. 이번 슬라이스에서는 각 라우트 목적지 View를 "준비중" placeholder로
  둔다.
- **Section 0 Header** 요소:
  - 좌측: "운테크" wordmark (고정 텍스트).
  - 우측: 알림 벨 SVG 아이콘 + unread count badge (카운트 0이면 배지 숨김, ≥100이면 "99+").
  - 우측: 프로필 아바타 원형 (displayName의 첫 글자).
  - 벨 탭 → `onBellTap` 핸들러 호출 (이번 단계에서는 빈 placeholder).
  - 아바타 탭 → `onAvatarTap` 핸들러 호출 (placeholder).
- **DI 프로토콜 5종 선언** (`ios/Woontech/Features/Home/Providers/` 하위):
  1. `UserProfileProviding` — `displayName: String`, `avatarInitial: String`.
  2. `NotificationCenterProviding` — `unreadCount: Int`.
  3. `HeroInvestingProviding` — (시그니처만 선언; 02에서 사용).
  4. `InsightsProviding` — (시그니처만 선언; 02에서 사용).
  5. `WeeklyEventsProviding` — (시그니처만 선언; 03에서 사용).
- 각 프로토콜에 대응하는 `MockXxx` 구현체를 함께 제공. Mock 기본값은 와이어프레임 예시
  (운테크, 길동, unreadCount=2 등).
- 주입 방식: `HomeDependencies` 단일 struct에 5개 providing 필드를 모아 `@EnvironmentObject`
  또는 생성자 주입으로 `HomeDashboardView`에 전달. 테스트 시 임의 mock 교체 가능.
- 런치 인자 `-openHome`으로 홈에 바로 진입 시, 주입된 provider가 기본 `MockHomeDependencies`여야 함.

## Non-functional constraints

- iOS 17+ (프로젝트가 NavigationStack 사용).
- `DesignTokens`에 홈 전용 색/간격이 필요하면 `ios/Woontech/Shared/DesignTokens.swift`에 추가.
- VoiceOver: 벨 = "알림 {count}개", 아바타 = "프로필 {displayName}".
- Dynamic Type Large까지 Header 잘림 없음.

## Out of scope

- Hero / Insights / Weekly / Share / PRO 등 모든 컨텐츠 카드 (02~03).
- 각 상세 화면 실제 내용 (04~06) — 이번 슬라이스에서는 "준비중" placeholder.
- 실제 알림 시스템, 실제 사용자 프로필 연동.
- 탭 바의 다른 탭으로의 라우팅.
- Quick Actions 섹션 (scope 제외 결정됨).

## Acceptance criteria

1. `RootView.route == .home`일 때 `HomeDashboardView`가 렌더된다 (이전 `HomePlaceholderView`는 더 이상 참조되지 않음).
2. `HomeDashboardView` 상단에 "운테크" wordmark가 항상 보인다.
3. `NotificationCenterProviding.unreadCount > 0`이면 벨 옆 배지에 숫자가 표시된다. `unreadCount == 0`이면 배지가 숨겨진다.
4. `NotificationCenterProviding.unreadCount == 150`으로 설정된 mock을 주입하면 배지 텍스트가 "99+"로 표시된다.
5. `UserProfileProviding.avatarInitial == "민"`인 mock 주입 시 아바타에 "민"이 표시된다.
6. 벨 탭 시 `onBellTap` 핸들러가 1회 호출된다 (테스트 스파이로 검증).
7. 아바타 탭 시 `onAvatarTap` 핸들러가 1회 호출된다.
8. `HomeDependencies`의 5개 providing 필드를 각각 임의 mock으로 교체하여 `HomeDashboardView`를 주입할 수 있고, 컴파일 및 렌더가 정상 동작한다.
9. `HomeDashboardView` 내부에 `NavigationStack`이 존재하며, 타입 안전한 라우트 enum(`HomeRoute`)으로 `investing`, `event(WeeklyEvent)`, `today`, `tabooPlaceholder`, `practicePlaceholder` 5개 케이스가 선언되어 있다.
10. 각 라우트 목적지 View가 "준비중" placeholder로 존재하고, 프로그램적으로 push 시 해당 placeholder가 보인다 (UI 테스트 — push API는 hidden button으로 트리거 허용).
11. Dynamic Type XL에서 Header 요소가 잘리거나 겹치지 않는다 (UI 테스트).
12. VoiceOver로 벨을 focus하면 "알림 2개" 레이블이 읽힌다 (기본 mock 기준).
