# implement-plan.md — WF3-05 이벤트 상세 (v2)

---

## 1. Goal

`WeeklyEvent` 1건을 받아 **의미 / 사주 관계 / 투자 관점** 3섹션과 **알림·캘린더·학습 CTA 3버튼**을 렌더하는 `EventDetailView`를 구현하고, `HomeRoute.event(event)` 목적지로 연결한다.

---

## 2. Affected Files

| 경로 | 신규(N) / 수정(M) | 비고 |
|------|-----------------|------|
| `Woontech/Features/Home/Detail/Event/EventDetailProviding.swift` | **N** | 프로토콜 + `EventDetailContent` + `MockEventDetailProvider` |
| `Woontech/Features/Home/Detail/Event/EventDetailView.swift` | **N** | 메인 뷰 + 내부 sub-view |
| `Woontech/Features/Home/HomeDependencies.swift` | **M** | `eventDetail: any EventDetailProviding` 프로퍼티 추가 |
| `Woontech/Features/Home/HomeDashboardView.swift` | **M** | `.event(let event)` case에 `EventPlaceholderView` → `EventDetailView` 교체, `HomeNavPushEvent` 버튼 유지 |
| `WoontechTests/Home/EventDetailViewTests.swift` | **N** | 단위 테스트 (AC-13 기반) |
| `WoontechUITests/Home/EventDetailUITests.swift` | **N** | UI 테스트 (AC-1~12, AC-14) |

---

## 3. Data Model / State Changes

### 3-1. 신규 모델 (`EventDetailProviding.swift`)

```
struct EventDetailContent {
    let meaning: String
    let sajuRelationFormula: String   // "경금 일주 × 병진 대운 = 편관"
    let sajuRelationNote: String      // "압박과 성장이 공존하는 10년"
    let investPerspectives: [String]  // bullet 배열
    let learnCTAText: String          // "📖 대운 학습하기 →"
}

protocol EventDetailProviding {
    func content(for eventID: WeeklyEvent.ID) -> EventDetailContent
}

struct MockEventDetailProvider: EventDetailProviding {
    // 와이어프레임 "대운 전환" 예시 기본값 제공
    // custom 값 주입을 위한 init(overrides:) 오버로드 포함
}
```

**ID 타입**: `WeeklyEvent.ID == UUID` — `WeeklyEvent.swift` 기존 정의 그대로 사용.

### 3-2. `HomeDependencies` 변경

- `var eventDetail: any EventDetailProviding = MockEventDetailProvider()` 프로퍼티 추가.
- `init(...)` 시그니처에 파라미터 1개 추가 (기본값 포함 → 기존 호출부 비파괴).

### 3-3. `HomeDashboardView` 변경

- `navigationDestination`의 `.event(let event)` 케이스:
  ```swift
  case .event(let event):
      EventDetailView(
          event: event,
          provider: homeDeps.eventDetail,
          onShareTap: { /* placeholder */ },
          onBellReminderTap: { /* placeholder */ },
          onAddToCalendarTap: { /* placeholder */ },
          onLearnTap: { /* placeholder */ }
      )
  ```
- Spy 카운터(`onShareTapCount` 등) 추가 및 overlay에 `accessibilityIdentifier` 노출 — UI 테스트용.

---

## 4. Implementation Steps

### Step 1 — `EventDetailContent` + `EventDetailProviding` 프로토콜 작성
- 파일: `EventDetailProviding.swift` (신규, `Features/Home/Detail/Event/` 폴더).
- `EventDetailContent` struct 정의 (5 프로퍼티).
- `EventDetailProviding` 프로토콜 정의 (`func content(for:) -> EventDetailContent`).

### Step 2 — `MockEventDetailProvider` 작성
- 같은 파일에 추가.
- 기본값: 와이어프레임 "대운 전환" 예시 (`meaning`, `sajuRelationFormula`, `sajuRelationNote`, `investPerspectives` 3개, `learnCTAText`).
- `init(meaning:sajuRelationFormula:sajuRelationNote:investPerspectives:learnCTAText:)` 사용자 정의 주입 허용.
- 모든 이벤트 ID에 동일 content 반환 (현재 단계).

### Step 3 — `EventDetailView` NavBar 영역 구현
- 파일: `EventDetailView.swift` (신규).
- `InvestingAttitudeDetailView`/`TodayDetailView` 패턴 준수: 커스텀 HStack NavBar.
- 타이틀 "이벤트 상세" (`accessibilityIdentifier: "EventDetailTitle"`).
- 좌측: `chevron.left` back 버튼 (`accessibilityIdentifier: "EventDetailBackButton"`).
  - `@Environment(\.dismiss)` 사용.
- 우측: "공유" 텍스트 버튼 → `onShareTap` 클로저 호출 (`accessibilityIdentifier: "EventDetailShareButton"`).

### Step 4 — 타이틀 카드 섹션 구현
- 큰 아이콘(`event.icon`) + 제목 bold(`event.title`) + `event.oneLiner`.
- 회색 박스(`.background(DesignTokens.gray)`) 내:
  - 날짜 `event.ddayDate` + D-day 텍스트(`"D-\(abs(event.dday))"`).
  - `event.badge` != nil → 우측 badge pill 렌더; nil → 숨김.
- `accessibilityIdentifier`: `"EventDetailTitleCard"`.

### Step 5 — "이 이벤트가 의미하는 것" 섹션
- 섹션 라벨 + `content.meaning` 본문 (`lineLimit(nil)`, `fixedSize(horizontal: false, vertical: true)` — Dynamic Type 대응).
- `accessibilityIdentifier: "EventDetailMeaningSection"`, 본문 텍스트 `"EventDetailMeaningText"`.

### Step 6 — "내 사주와의 관계" 섹션
- 회색 박스 내:
  - `content.sajuRelationFormula` — `.font(.system(size: ..., weight: .bold))` + `accessibilityIdentifier: "EventDetailSajuFormula"`.
  - `content.sajuRelationNote` — `.font(.caption)` + `accessibilityIdentifier: "EventDetailSajuNote"`.
- 섹션 컨테이너 `accessibilityIdentifier: "EventDetailSajuSection"`.

### Step 7 — "💹 투자 관점" 섹션
- `content.investPerspectives.isEmpty` 시 섹션 전체(헤더 + 리스트) 숨김.
- 비어 있지 않으면: 섹션 라벨 + bullet 리스트 (`ForEach(enumerated)`).
  - bullet 각 항목 `accessibilityIdentifier: "EventDetailInvestBullet_\(index)"`.
- 섹션 컨테이너 `accessibilityIdentifier: "EventDetailInvestSection"`.
- `lineLimit(nil)` + `fixedSize` — Dynamic Type 대응.

### Step 8 — 액션 버튼 3개
- 버튼 높이 38pt, 폰트 11pt (spec §Non-functional).
- 세로 `VStack`:
  1. "🔔 D-7 푸시 알림 받기" → `onBellReminderTap` (`accessibilityIdentifier: "EventDetailBellButton"`).
  2. "📅 캘린더에 추가" → `onAddToCalendarTap` (`accessibilityIdentifier: "EventDetailCalendarButton"`).
  3. `content.learnCTAText` (primary 스타일 — DesignTokens.ink 배경, 흰 텍스트) → `onLearnTap` (`accessibilityIdentifier: "EventDetailLearnButton"`).
- 버튼 3개 컨테이너 `accessibilityIdentifier: "EventDetailActionButtons"`.

### Step 9 — Disclaimer 푸터
- `DisclaimerView()` 재사용 (기존 컴포넌트).
- ScrollView 내 가장 마지막 요소로 배치.

### Step 9a — VoiceOver 접근성 (non-functional constraint)

**레이아웃 순서 보장**:
- 전체 뷰를 `VStack { NavBarHStack; ScrollView { … } }` 로 구성하면 SwiftUI의 기본 VoiceOver 순서(위→아래, 좌→우)가 spec 요구(NavBar → 타이틀 카드 → 의미 → 사주 관계 → 투자 관점 → 액션 버튼 3개 → disclaimer)를 자연스럽게 충족한다. 이 구조를 유지해야 하며, `ZStack` 또는 overlay 레이아웃으로 NavBar를 구현하면 순서가 깨질 수 있으므로 금지.

**섹션 컨테이너 그룹핑**:
- `EventDetailMeaningSection` 컨테이너(라벨 + 본문 VStack)에 `.accessibilityElement(children: .contain)` 적용 → 섹션 라벨과 본문이 하나의 논리 단위로 포커스됨.
- `EventDetailSajuSection` 컨테이너(회색 박스)에 동일하게 `.accessibilityElement(children: .contain)` 적용.
- `EventDetailInvestSection` 컨테이너(헤더 + bullet VStack)에 동일하게 `.accessibilityElement(children: .contain)` 적용.
- 액션 버튼 컨테이너(`EventDetailActionButtons`)는 개별 버튼 포커스가 필요하므로 `.accessibilityElement(children: .contain)` **미적용**. 버튼 3개가 순서대로 독립 포커스를 받아야 함.

**NavBar HStack**:
- 커스텀 NavBar HStack을 `.accessibilityElement(children: .contain)`으로 래핑하지 않는다. Back 버튼, 타이틀, 공유 버튼이 각각 독립 포커스를 받아야 하며 좌→우 순서가 보장됨.

### Step 10 — `HomeDependencies` 수정
- `eventDetail: any EventDetailProviding` 프로퍼티 추가, 기본값 `MockEventDetailProvider()`.
- `init` 파라미터 추가 (기본값 제공).

### Step 11 — `HomeDashboardView` 수정
- `navigationDestination` `.event(let event)` 케이스 교체.
- Spy 카운터 4개 추가: `onShareTapCount`, `onBellReminderTapCount`, `onAddToCalendarTapCount`, `onLearnTapCount`.
  - overlay opacity(0) staticText로 노출.
- `HomeNavPushEvent` 버튼: 이미 존재하므로 유지 (변경 불필요).

**UI 테스트용 런치 인수 처리** (AC-13 view-binding 검증):
- `HomeDependencies` 또는 앱 엔트리 포인트에서 아래 런치 인수를 처리하여 `MockEventDetailProvider`를 커스텀 값으로 초기화한다:
  - `-mockCustomMeaning <string>` → `MockEventDetailProvider(meaning: <string>, …)`.
  - `-mockCustomLearnCTA <string>` → `MockEventDetailProvider(learnCTAText: <string>, …)`.
  - `-mockCustomSajuFormula <string>` → `MockEventDetailProvider(sajuRelationFormula: <string>, …)`.
- 이미 UI10에서 사용하는 `-mockEmptyInvestPerspectives` 런치 인수 패턴(`ProcessInfo.processInfo.arguments.contains(…)`)을 동일하게 적용한다.

### Step 12 — `HomeRouteDestinations.swift` 수정
- `EventPlaceholderView`를 deprecated 마킹.
  - *(선택)* 또는 그대로 두고 `HomeDashboardView`에서만 교체해도 충분.

---

## 5. Unit Test Plan

파일: `WoontechTests/Home/EventDetailViewTests.swift`

| 테스트 ID | 대상 AC | 설명 |
|-----------|---------|------|
| U1 | AC-13 | `MockEventDetailProvider()` 기본값 — `meaning`, `sajuRelationFormula`, `sajuRelationNote`, `learnCTAText`가 와이어프레임 문자열과 일치 |
| U2 | AC-13 | `MockEventDetailProvider()` 기본값 — `investPerspectives` 배열 길이 3, 각 항목 내용 검증 |
| U3 | AC-13 | 사용자 정의 `meaning` 주입 시 `content(for:).meaning` 반환값 일치 |
| U4 | AC-13 | 사용자 정의 `investPerspectives` 주입 시 배열 길이·내용 일치 |
| U5 | AC-13 | 사용자 정의 `sajuRelationFormula` / `sajuRelationNote` 주입 후 반환값 검증 |
| U6 | AC-13 | 사용자 정의 `learnCTAText` 주입 후 반환값 검증 |
| U7 | AC-5  | `investPerspectives` 빈 배열 주입 → `isEmpty == true` |
| U8 | AC-6  | `learnCTAText` 비어 있지 않음 (기본값 검증) |
| U9 | AC-2  | `WeeklyEvent.badge == nil` 일 때 badge 분기 로직 (이벤트 모델 프로퍼티 검증) |
| U10 | AC-2 | `WeeklyEvent.badge != nil` 일 때 badge 값 검증 |
| U11 | — | `EventDetailView` 뷰 생성 시 crash 없음 (기본 smoke test) |

---

## 6. UI Test Plan

파일: `WoontechUITests/Home/EventDetailUITests.swift`

**공통 설정**: `-openHome` 런치 인수 + `HomeNavPushEvent` 숨김 버튼으로 진입.

| 테스트 ID | 대상 AC | 설명 |
|-----------|---------|------|
| UI1 | AC-1  | `HomeNavPushEvent` 탭 후 `EventDetailTitle` 존재 확인 (push 성공) |
| UI2 | AC-1  | `EventCardView` 직접 탭 → `EventDetailTitle` 나타남 (이벤트 카드 경유 진입) |
| UI3 | AC-2  | NavBar 타이틀 label == "이벤트 상세" |
| UI4 | AC-2  | `EventDetailTitle` + `EventDetailBackButton` + `EventDetailShareButton` 존재 |
| UI5 | AC-2  | 타이틀 카드: `event.icon`, `event.title`, `event.oneLiner`, `event.ddayDate`, D-day 텍스트 포함 |
| UI6 | AC-2  | badge nil 이벤트: badge pill 미존재 / badge 있는 이벤트: badge pill 존재 |
| UI7 | AC-3  | `EventDetailMeaningSection` 존재, `EventDetailMeaningText` 기본 mock 문자열 포함 |
| UI8 | AC-4  | `EventDetailSajuFormula` 기본 mock 문자열, `EventDetailSajuNote` 기본 mock 문자열 |
| UI9 | AC-5  | 기본 mock: `EventDetailInvestBullet_0/1/2` 모두 존재 |
| UI10 | AC-5 | mock `investPerspectives = []` 런치 인수 활용 시 `EventDetailInvestSection` 미존재 |
| UI11 | AC-6 | `EventDetailActionButtons` 내 버튼 3개(`EventDetailBellButton`, `EventDetailCalendarButton`, `EventDetailLearnButton`) 존재 |
| UI12 | AC-6 | `EventDetailLearnButton` label == 기본 mock `learnCTAText` 값 |
| UI13 | AC-7 | `EventDetailBellButton` 탭 → spy 카운터 `EventDetailBellTapCount` 1 증가 |
| UI14 | AC-8 | `EventDetailCalendarButton` 탭 → spy 카운터 `EventDetailCalendarTapCount` 1 증가 |
| UI15 | AC-9 | `EventDetailLearnButton` 탭 → spy 카운터 `EventDetailLearnTapCount` 1 증가 |
| UI16 | AC-10 | `EventDetailShareButton` 탭 → spy 카운터 `EventDetailShareTapCount` 1 증가 |
| UI17 | AC-11 | `EventDetailBackButton` 탭 → `HomeDashboardRoot` 복귀 |
| UI18 | AC-12 | 스크롤 끝 `DisclaimerText` 존재 |
| UI19 | AC-14 | Dynamic Type XL 환경(`UIContentSizeCategoryOverride = UICTContentSizeCategoryAccessibilityXL`) — `EventDetailMeaningText` frame.height > 0, label에 "…" 미포함; `EventDetailInvestBullet_0` 동일 검증 |
| UI20 | AC-13 | `-mockCustomMeaning "커스텀의미텍스트"` + `-mockCustomLearnCTA "커스텀CTA텍스트"` 런치 인수 → `EventDetailView` 진입 후 `EventDetailMeaningText` label에 "커스텀의미텍스트" 포함, `EventDetailLearnButton` label == "커스텀CTA텍스트" (provider 주입 → 뷰 바인딩 엔드-투-엔드 검증) |
| UI21 | AC-13 | `-mockCustomSajuFormula "커스텀공식"` 런치 인수 → `EventDetailSajuFormula` label에 "커스텀공식" 포함 (sajuRelationFormula 바인딩 검증) |

---

## 7. Risks / Open Questions

1. **`EventDetailProviding` 의존성 주입 전략**: 현재 `HomeDashboardView`는 `HomeDependencies` EnvironmentObject를 사용. `EventDetailView`가 이벤트마다 다른 컨텐츠를 반환해야 한다면 향후 백엔드 연결 시 provider가 이벤트 타입(`.daewoon`, `.jeolgi` 등) 기반 분기를 해야 할 수 있음. 현재 단계는 ID → 단일 mock content로 충분.

2. **Spy 카운터 전달 방식**: `EventDetailView`는 클로저 4개를 파라미터로 받는다. `HomeDashboardView`의 `navigationDestination` 클로저 내에서 spy 카운터를 갱신하려면 `@State` 카운터를 view body에서 capture해야 하는데, SwiftUI의 클로저 capture 시 `@State` 바인딩이 올바르게 동작하는지 확인 필요.

3. **`HomeNavPushEvent` 버튼의 이벤트 ID**: 현재 `MockWeeklyEventsProvider().events()[0]`을 사용. badge가 nil/non-nil인 두 이벤트를 각각 테스트하려면 런치 인수(`-mockEventWithBadge`, `-mockEventNoBadge`)를 추가해야 함 — UI테스트 UI6 구현 시 결정 필요.

4. **"공유" 버튼 스타일**: 스펙에 "텍스트 버튼"으로 명시됨. DesignTokens에 primary 색상 토큰이 별도 없으므로 `DesignTokens.ink` 사용 예정; 실제 디자인 확정 전 placeholder로 처리.

5. **Dynamic Type 테스트 환경**: `UIContentSizeCategoryOverride` launch env 키는 iOS 시뮬레이터에서 동작하나, Xcode 버전에 따라 실제 적용 타이밍이 다를 수 있음 — `TodayDetailUITests`와 동일한 패턴(`app.launchEnvironment[...]`) 적용.

6. **`HomeRouteDestinations.swift`의 `EventPlaceholderView`**: deprecated로 마킹하거나 삭제 여부는 팀 컨벤션에 따라 결정. `InvestingPlaceholderView` / `TodayPlaceholderView` 패턴(@available deprecated)을 따름.
