# WF3-03 — 홈 below-the-fold (Weekly 흐름 + 공유 훅 + PRO 티저 + Disclaimer)

## User story / motivation

홈 아래로 스크롤했을 때 보이는 영역을 구성한다. 핵심은 **이번 주 흐름**(이번 주 /
이번 달 / 3개월 이내 3개 시간축 그룹으로 묶인 다가올 이벤트 카드 리스트)이며, 이벤트
카드 탭 시 `HomeRoute.event(WeeklyEvent)`가 push된다. 아래쪽엔 바이럴 훅인 **공유
카드**와 업셀용 **PRO 티저**, 그리고 면책 **Disclaimer**가 차례로 배치된다.
WF3-01에서 선언만 해둔 `WeeklyEventsProviding`의 mock 구현을 완성한다.

## Functional requirements

- `HomeDashboardView` 컨텐츠 슬롯은 단일 수직 `ScrollView`여야 하며, above-fold(WF3-02)와 below-fold가 **한 스크롤 뷰 내에 연결**된다.
- **Section 7 이번 주 흐름**:
  - 섹션 헤더: 제목 "이번 주 흐름" + 서브타이틀 "다가올 절기·대운 이벤트" + 우측 "캘린더 보기 ›" (탭 시 `onCalendarTap` placeholder).
  - 시간축 그룹 divider: `["이번 주", "이번 달", "3개월 이내"]` 순서로 렌더. 해당 그룹에 속한 이벤트가 0개면 **그룹 divider + 카드 영역 모두 숨김**.
  - 각 이벤트 카드(`V6EventCard` 와이어프레임 기준):
    - 좌측 icon (이모지).
    - title (bold) + 옵션 badge "중요" (impact=positive 이고 `event.badge == "중요"`일 때만).
    - oneLiner (한줄).
    - 우측 상단 D-day 배지 (예: "D-4").
    - 카드 본문 하단 날짜 텍스트 (예: "4/27 월").
    - 회색 배경 박스: `💹 {investContext}` + 우측 "알림 ›" 보조 텍스트.
  - **impact=negative** 이벤트 카드: 빨간 border + 좌측 3pt 세로 accent bar + D-day 배지 색상도 빨강.
  - **impact=positive** 이벤트 카드: 기본 border + 선택적 "중요" 배지.
  - 카드 전체 탭 → `HomeRoute.event(event)` push (해당 이벤트 payload 전달).
- **Section 8 공유 훅**:
  - 회색 카드 안에 💌 아이콘 + 제목 "내 사주 카드로 친구 초대" + 설명 "둘 다 PRO 1개월 무료".
  - 하단 버튼 2개: "카드 미리보기"(`onSharePreviewTap`), "공유하기"(`onShareTap`).
- **Section 9 PRO 티저**:
  - 자물쇠 아이콘 + 제목 "PRO로 더 깊은 분석".
  - 기능 3-bullet: provider가 반환한 배열을 순서대로 렌더 (기본 mock: `["6개월 흐름 리포트", "성향 vs 실제 행동 주간 리포트", "AI 사주 상담사"]`).
  - 버튼 "7일 무료 체험 →" (`onProTrialTap`).
- **Disclaimer**: ScrollView 최하단에 `WF2` 공용 면책 문구 재사용 — "본 앱은 학습·참고용이며 투자 권유가 아닙니다…".
- ScrollView 하단 padding은 탭 바 높이 + 16pt.

## Non-functional constraints

- `WeeklyEventsProviding` 반환 타입 `[WeeklyEvent]`는 WF3-05에서도 같은 모델을 재사용할 수 있도록 `ios/Woontech/Shared/` 하위에 둔다.
- `WeeklyEvent` 필드 최소: `id`, `type`(daewoon/jeolgi/hapchung/special), `icon`, `title`, `hanja?`, `dday`, `ddayDate`, `impact`(positive/neutral/negative), `oneLiner`, `investContext`, `badge?`, `timeGroup`("이번 주"/"이번 달"/"3개월 이내").
- Mock 기본값은 와이어프레임 `V6_EVENTS` 4건 그대로.
- Dynamic Type Large: 카드 내 텍스트 wrapping.

## Out of scope

- 이벤트 상세 화면 내용 (WF3-05).
- 실제 공유 시트, 실제 캘린더 연동, 실제 푸시 구독, 실제 PRO 결제.
- Hero/Insights (WF3-02).
- "캘린더 보기" 탭 목적지 화면 — placeholder action만.

## Acceptance criteria

1. `HomeDashboardView`의 컨텐츠 영역은 단일 수직 `ScrollView`이며, Hero → Insights → Weekly → Share → PRO → Disclaimer 순서로 위→아래 스크롤 가능하다 (UI 테스트).
2. `WeeklyEventsProviding`이 반환한 이벤트가 `timeGroup` 기준 "이번 주" → "이번 달" → "3개월 이내" 순서로 그룹핑되어 렌더된다.
3. 특정 `timeGroup`에 이벤트가 없으면 해당 divider와 카드 영역이 모두 숨겨진다. (mock에 "이번 달" 이벤트만 있는 경우 "이번 주", "3개월 이내" 그룹 숨김)
4. `impact == .negative`인 이벤트 카드는 빨간 border + 좌측 accent bar + 빨간 D-day 배지 색상을 갖는다 (스냅샷 또는 조건부 modifier 테스트).
5. `impact == .positive && event.badge == "중요"`인 카드는 제목 옆에 "중요" pill 배지를 표시한다. 그 외 조건에서는 배지가 없다.
6. 이벤트 카드 탭 시 `HomeRoute.event(해당 event)`가 path에 append되고, 정확한 `WeeklyEvent` payload가 전달된다 (스파이로 event.id 일치 검증).
7. 공유 카드 "카드 미리보기" 탭 시 `onSharePreviewTap` 1회 호출; "공유하기" 탭 시 `onShareTap` 1회 호출.
8. PRO 티저 기능 bullet은 provider가 반환한 배열 길이만큼 정확히 렌더된다. (배열 길이 0일 때 bullet 영역 숨김)
9. "7일 무료 체험 →" 버튼 탭 시 `onProTrialTap` 1회 호출.
10. "캘린더 보기 ›" 탭 시 `onCalendarTap` 1회 호출.
11. Disclaimer 텍스트가 ScrollView 최하단 요소로 존재한다.
12. `MockWeeklyEventsProvider`를 빈 배열로 교체 시 Section 7의 섹션 헤더는 보이되 모든 그룹 divider/카드가 숨겨진다. (또는 섹션 헤더 전체 숨김 — 구현 시 고정하고 테스트 반영)
13. Dynamic Type XL에서 이벤트 카드 내 `investContext` 텍스트가 잘리지 않고 wrapping된다.
