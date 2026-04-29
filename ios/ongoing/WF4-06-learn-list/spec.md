# WF4-06 — 사주 공부 리스트

## User story / motivation

사주 탭 below-fold(WF4-03)의 "전체 ›", 학습 경로 카드, 또는 다른 진입점에서 push되는
**사주 공부 리스트** 화면. 카테고리 필터 pill로 코스를 압축해 보여주고, 주간 학습 진행
배너로 동기를 강화하며, 듀오링고식 코스 셀(완료 / 현재 / 미완료 / 잠금 4상태)로 학습
경로를 한눈에 보여준다. 추천 아티클 카드로 가벼운 콘텐츠 탐색도 함께 제공한다.

## Functional requirements

- 새 View: `SajuLearnListView`. `SajuTabView`의 NavigationStack에서 `SajuRoute.learn` 케이스의
  목적지(WF4-01의 placeholder를 본 화면으로 교체).
- NavBar:
  - 타이틀 "사주 공부".
  - Back 버튼 — 탭 시 pop.
  - 우측 액션 영역: muted 텍스트 "검색"(시각만 표시. 본 슬라이스에서는 탭 시 no-op +
    accessibility hint "준비중").
- 데이터: WF4-01에서 시그니처만 선언된 `SajuLearningPathProviding`을 본 슬라이스에서
  본격 사용한다. 추가로 본 화면에서 필요한 인터페이스를 동일 프로토콜에 보강한다(WF4-03의
  진행률 그리드용 메서드와 충돌 없이 공존).
  - `categories: [LearnCategory]` — 길이 **고정 6**, 순서 `[전체, 입문, 오행, 십성, 대운,
    합충]`. item `(label: String)`.
  - `weeklyProgress: WeeklyProgress` — `(streakDays: Int, completedCount: Int, totalCount:
    Int, ratio: Double)`. `ratio = completedCount / totalCount` 또는 0.0~1.0 정수.
  - `course: CourseSection` — 단일 입문 코스를 본 슬라이스의 기본 노출 대상으로 한다.
    `(name: String, lessonCount: Int, averageMinutes: Int, lessons: [LessonRow])`.
  - `LessonRow` = `(id: String, number: Int, title: String, durationLabel: String, status:
    LessonStatus)`. `LessonStatus = .completed | .current | .pending | .locked`.
  - `recommendedArticles: [Article]` — 길이 0~N. item `(title: String, metaLabel: String)`.
- `MockSajuLearningPathProvider` 기본값(와이어프레임과 동일):
  - categories: 위 6개.
  - weeklyProgress: streak=3, completed=3, total=5, ratio=0.6.
  - course: name "입문", lessonCount=7, averageMinutes=3, lessons:
    1. completed "사주란 무엇인가" 3분.
    2. completed "천간과 지지" 4분.
    3. completed "오행의 의미" 3분.
    4. current "일간이 나를 나타낸다" 5분.
    5. locked "지장간이란" 4분.
    6. locked "절기와 월주" 4분.
    7. locked "내 사주를 읽는 법" 6분.
  - recommendedArticles: 2건(예: "내 사주 일간이 丙(병)이면 어떤 사람?", "水가 없는 사주,
    투자에 미치는 영향").
- 레이아웃(수직 `ScrollView`, 좌우 16pt padding):
  1. **카테고리 필터 Pill 가로 스크롤** — 6 pills, **고정 순서**. 첫 진입 시 "전체"가 선택
     상태(검정 배경 + 흰 글씨, bold). 다른 pill 탭 시 해당 pill만 선택 상태로 전환되며 본
     슬라이스에서는 코스 리스트 표시는 변화하지 않는다(필터 적용은 후속 범위 외, 시각 상태만
     변경).
  2. **주간 진행 배너 카드** — 좌측: muted "이번 주 학습" + `🔥 연속 {streakDays}일` 배지 +
     bold "{completed} / {total}강 완료". 우측: 작은 placeholder(% 라벨) 영역. 카드 하단:
     진행률 바(높이 4pt, 채움 = `ratio` × 100%).
  3. **코스 헤더** — 상단 18pt 마진. 좌측 "{course.name} 코스"(bold 12pt), 우측 muted
     "{lessonCount}강 · 평균 {averageMinutes}분".
  4. **코스 리스트** — `course.lessons` 순서대로 카드 렌더(카드 간 6pt). 각 카드:
     - 좌측 원형 인디케이터(28×28pt):
       - completed → 검정 배경 + 흰 체크 SVG.
       - current → 흰 배경 + 검정 테두리(굵게) + 번호 텍스트(검정).
       - pending → 흰 배경 + 회색 테두리 + 번호 텍스트(검정).
       - locked → 흰 배경 + 회색 테두리 + 번호 텍스트(muted).
     - 가운데 영역: 타이틀(bold 12pt; current 카드는 더 진하게) + 메타 라인(muted 9pt) =
       `durationLabel` (current이면 추가로 ` · 이어보기` 텍스트).
     - 우측 영역: locked → 자물쇠 SVG(muted), 그 외 → muted `›` chevron.
   - 카드 탭 동작:
     - completed / current / pending → `SajuRoute.lesson(id: row.id)` push.
     - locked → push하지 않고 토스트 "이전 강의를 먼저 완료하세요" 노출(2초 후 자동 닫힘).
  5. **추천 아티클 섹션** — 18pt 상단 마진. 헤더 "이번 주 읽을거리" + 카드 N개. 각 카드는
     좌측 작은 placeholder(44×44pt) + 우측 title(bold 11pt) + meta(muted 9pt). 본 슬라이스
     에서 카드 탭은 no-op + accessibility hint "준비중"(별도 아티클 화면은 본 WF4 범위 외).
- 카테고리 pill 선택 상태는 화면 인스턴스가 살아있는 동안만 유지하면 된다(영속화 불필요).

## Non-functional constraints

- iOS 17+ NavigationStack toolbar API.
- Pill 가로 스크롤은 좌우 16pt padding과 카드 간 6pt 간격을 유지하며, content 길이가 화면
  너비를 넘으면 자연스럽게 가로 스크롤된다.
- 진행률 바 ratio는 0.0~1.0 범위 밖 값이 들어와도 clamp.
- Dynamic Type Large까지 모든 텍스트 wrapping OK. 인디케이터(28pt) 크기는 유지.
- VoiceOver:
  - Pill = "{label}, {선택 상태}".
  - 진행 배너 = "이번 주 학습 진행, {completed}강 완료 중 {total}강, 연속 {streakDays}일".
  - 코스 셀 = "{number}강 {title}, {durationLabel}, 상태 {상태 한국어}". current는 "이어보기".
    locked는 트레잇 "잠김".
- 코스 셀, pill, 추천 카드 hit target 44×44pt 이상.
- 토스트는 화면 하단 safe area 위쪽으로 띄우고 VoiceOver `announcement`로도 읽힌다.

## Out of scope

- 사주 탭 홈(원국/카테고리/공부 섹션) — WF4-02 / WF4-03.
- 오행/십성 상세 — WF4-04 / WF4-05.
- 레슨 상세 본문 — WF4-07. 본 슬라이스에서는 lesson 라우트 push까지만 검증.
- 카테고리 pill을 통한 실제 코스 필터링(여러 코스 노출, 입문 외 코스 진입 분기) — 현재
  슬라이스에서는 단일 입문 코스만 노출하고 pill 선택 상태만 시각 반영. 후속 범위.
- 추천 아티클 상세 화면 / 외부 링크.
- 학습 진행 영속화·서버 동기화.
- "검색" 액션 본문.
- 사용자 정렬·완료 표시 토글.

## Acceptance criteria

각 항목은 unit/UI 테스트로 검증 가능해야 한다.

1. WF4-03의 "전체 ›" 또는 학습 경로 카드 탭 시 `SajuLearnListView`가 push된다.
2. NavBar 타이틀은 "사주 공부"이고, 우측에 muted "검색" 텍스트가 표시된다.
3. 카테고리 pill 영역은 항상 `[전체, 입문, 오행, 십성, 대운, 합충]` 순서로 6개 렌더된다.
4. 첫 진입 시 "전체" pill이 선택 상태(검정 배경 + 흰 글씨, bold)이며 다른 pill은 흰 배경 +
   회색 테두리 상태이다.
5. 임의의 pill 탭 시 해당 pill만 선택 상태가 되고 직전 선택 pill은 미선택 상태로 전환된다
   (단일 선택). 본 슬라이스에서 코스 리스트의 표시 내용은 변화하지 않는다.
6. 진행 배너의 streak 배지는 `streakDays > 0`일 때만 표시된다(0이면 숨김). 텍스트 "{completed}
   / {total}강 완료"가 정확히 바인딩된다.
7. 진행률 바 너비 = `clamp(ratio, 0, 1) × 100%`를 정확히 따른다(`MockSajuLearningPathProvider`
   기본값 0.6 → 60%).
8. 코스 헤더에 `course.name + " 코스"`와 `"{lessonCount}강 · 평균 {averageMinutes}분"`이 정확히
   바인딩된다.
9. 코스 리스트는 `course.lessons` 배열 순서로 정확히 렌더되며 카드 개수는 `course.lessonCount`
   와 일치한다(`MockSajuLearningPathProvider` 기본값 기준 7개).
10. completed 카드의 좌측 인디케이터는 검정 배경 + 흰 체크 SVG 형태로 렌더된다.
11. current 카드의 좌측 인디케이터는 흰 배경 + 검정 굵은 테두리 + 번호 텍스트로 렌더되며,
    가운데 메타 라인 끝에 ` · 이어보기` 텍스트가 추가된다. 카드 타이틀은 bold가 더 진하다.
12. pending 카드의 인디케이터는 회색 테두리 + 번호 텍스트, 우측에 `›` chevron이 표시된다.
13. locked 카드의 인디케이터는 회색 테두리 + 번호(muted), 우측에 자물쇠 SVG가 표시된다.
14. completed/current/pending 카드 탭 시 `SajuRoute.lesson(id: row.id)`가 NavigationStack
    path에 append된다(예: 4강 current 탭 시 id="L4" 류 mock 식별자가 그대로 전달).
15. locked 카드 탭 시 path는 변화하지 않고, 화면 하단에 "이전 강의를 먼저 완료하세요" 토스트
    가 노출된다(2초 후 자동 닫힘). VoiceOver `announcement`로 동일 문구가 읽힌다.
16. 추천 아티클 섹션은 `recommendedArticles.count` 개수의 카드를 렌더한다(빈 배열이면 헤더
    포함 섹션 전체 숨김).
17. 추천 아티클 카드 탭 시 path는 변화하지 않는다(no-op). VoiceOver hint에 "준비중"이 노출
    된다.
18. NavBar "검색" 영역 탭은 no-op이며, accessibility hint "준비중"이 노출된다.
19. 모든 인터랙티브 요소(pill 6개, 코스 카드 N개, 추천 카드, NavBar 검색)의 hit target이
    44×44pt 이상을 만족한다.
20. Dynamic Type XL에서 코스 카드 타이틀/메타가 wrapping되어 잘리지 않으며, 인디케이터 원의
    크기가 28pt를 유지한다.
