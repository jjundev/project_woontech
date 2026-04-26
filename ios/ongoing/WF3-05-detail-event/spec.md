# WF3-05 — 이벤트 상세 (Weekly 카드 탭 목적지)

## User story / motivation

홈 "이번 주 흐름"의 이벤트 카드(대운/절기/합충/특수일)를 탭했을 때 push되는 상세
화면. 해당 이벤트의 **의미**, **내 사주와의 관계**, **투자 관점** 3섹션과 알림/캘린더/학습
CTA 3버튼을 제공한다. 와이어프레임 기준: `ScrWeeklyDetail` (screens-02-home-v6.jsx).
입력은 WF3-03에서 전달받은 `WeeklyEvent` 1건이며, 이벤트 ID별 보충 컨텐츠는
`EventDetailProviding`에서 주입받는다.

## Functional requirements

- 새 View: `EventDetailView(event: WeeklyEvent)`. `HomeRoute.event(event)` 목적지.
- NavBar:
  - 타이틀 "이벤트 상세".
  - Back(자동).
  - 우측 액션 "공유" 텍스트 버튼 → `onShareTap` placeholder.
- 신규 provider `EventDetailProviding`:
  - `func content(for eventID: WeeklyEvent.ID) -> EventDetailContent`
  - `EventDetailContent`: `meaning: String`, `sajuRelationFormula: String`, `sajuRelationNote: String`, `investPerspectives: [String]`, `learnCTAText: String`.
- `MockEventDetailProvider` 기본값은 와이어프레임의 "대운 전환" 예시:
  - meaning = "10년 주기로 바뀌는 큰 환경 변화…",
  - sajuRelationFormula = "경금 일주 × 병진 대운 = 편관",
  - sajuRelationNote = "압박과 성장이 공존하는 10년",
  - investPerspectives = ["안정형 → 도전형 전환 신호", "단, 충동적 결정 경계", "새 자산군 탐색 참고 시기"],
  - learnCTAText = "📖 대운 학습하기 →".
- 레이아웃(수직 `ScrollView`):
  1. **타이틀 카드**: 큰 아이콘 + 제목(bold) + oneLiner; 회색 박스 내 날짜(`ddayDate`) + D-day(`dday`) + 우측 badge(있을 때).
  2. **이 이벤트가 의미하는 것** — 섹션 라벨 + `meaning` 본문.
  3. **내 사주와의 관계** — 회색 박스 내 `sajuRelationFormula`(bold) + `sajuRelationNote`(caption).
  4. **💹 투자 관점** — 섹션 라벨 + `investPerspectives` bullet 리스트.
  5. **액션 버튼 3개** (세로 stack):
     - "🔔 D-7 푸시 알림 받기" → `onBellReminderTap` placeholder.
     - "📅 캘린더에 추가" → `onAddToCalendarTap` placeholder.
     - `learnCTAText` (primary 스타일) → `onLearnTap` placeholder.
  6. **Disclaimer** 푸터.

## Non-functional constraints

- `WeeklyEvent` 모델은 WF3-03에서 정의된 타입을 **import해서 그대로 사용** (신규 타입 도입 금지).
- 모든 액션 버튼 높이 38pt, 폰트 11pt(와이어프레임 기준).
- Dynamic Type Large: 본문/bullet 모두 wrapping.
- VoiceOver 순서: NavBar → 타이틀 카드 → 의미 → 사주 관계 → 투자 관점 → 액션 버튼 3개 → disclaimer.

## Out of scope

- 실제 푸시 알림 등록 / 캘린더 권한 요청 / 딥링크 학습 콘텐츠.
- 공유 시트 실제 렌더.
- 다른 이벤트로의 가로 스와이프 네비게이션.
- 알림 on/off 토글 상태 저장.

## Acceptance criteria

1. Weekly 카드 탭 시(WF3-03) `EventDetailView`가 전달된 `WeeklyEvent`로 초기화되어 push된다. (WF3-03 acceptance #6과 짝)
2. 타이틀 카드에 이벤트의 `icon`, `title`, `oneLiner`, `ddayDate`, `dday`가 모두 표시된다. `event.badge`가 nil이면 badge pill이 숨겨지고, 존재하면 우측에 렌더된다.
3. "이 이벤트가 의미하는 것" 섹션은 `EventDetailProviding.content(for: event.id).meaning`을 본문으로 표시한다.
4. "내 사주와의 관계" 섹션은 `sajuRelationFormula`를 bold, `sajuRelationNote`를 caption으로 렌더한다.
5. "💹 투자 관점" 섹션은 `investPerspectives` 배열 길이만큼 bullet을 렌더한다. 배열이 비어 있으면 섹션 전체(헤더 포함) 숨김.
6. 액션 버튼은 항상 3개 렌더되며, 세 번째 버튼 텍스트는 `learnCTAText` 값이다.
7. "🔔 D-7 푸시 알림 받기" 탭 시 `onBellReminderTap` 1회 호출.
8. "📅 캘린더에 추가" 탭 시 `onAddToCalendarTap` 1회 호출.
9. 세 번째 CTA 탭 시 `onLearnTap` 1회 호출.
10. NavBar "공유" 탭 시 `onShareTap` 1회 호출.
11. Back 탭 시 pop되어 홈 below-fold 스크롤 위치가 유지된다 (SwiftUI NavigationStack 기본 동작 확인).
12. Disclaimer가 ScrollView 최하단 요소로 존재한다.
13. `EventDetailProviding`을 mock으로 교체하고 사용자 정의 `meaning`, `investPerspectives`, 등을 주입하면 모든 섹션이 해당 값으로 바인딩된다 (단위 테스트).
14. Dynamic Type XL에서 `meaning` 본문과 `investPerspectives` bullet이 wrapping되어 잘리지 않는다 (UI 테스트).
