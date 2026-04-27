# WF4-03 — 사주 탭 below-the-fold (사주 공부하기 섹션 + Disclaimer)

## User story / motivation

사주 탭 홈 스크롤 하단의 **사주 공부하기 섹션**을 구현해 학습 습관화 + 리텐션을 유도한다.
연속 학습 일수 배지로 동기를 자극하고, "오늘의 한 가지" 카드로 가벼운 시작점을 제공하며,
4코스 학습 경로 그리드와 용어 사전 카드로 전체 학습 지도를 한눈에 보여준다. 이 섹션의
진행률 데이터는 WF4-01에서 시그니처만 선언된 `SajuLearningPathProviding`의 mock 구현을
완성해 바인딩한다.

## Functional requirements

- WF4-02에서 렌더되는 above-fold(원국 카드 + 5 카테고리 카드) 바로 **아래**에 본 섹션이
  렌더된다(섹션 사이 18pt 상단 마진).
- 본 슬라이스 종료 시점에 사주 탭 홈은 above-fold + below-fold가 결합된 **단일 스크롤 화면**
  형태로 완성된다.

### Block A — 사주 공부하기 섹션 헤더

- 좌측: "사주 공부하기" 텍스트(bold 12pt) + 우측 옆에 연속 학습 배지(예: `🔥 연속 3일`).
  배지는 둥근 pill 형태(테두리 + 회색 배경).
- 우측 정렬: 보조 링크 "전체 ›"(muted). 탭 시 `SajuRoute.learn` push.
- 데이터: `SajuLearningPathProviding.streakDays: Int`. 0이면 배지 자체를 숨기고 헤더 텍스트만
  표시한다.

### Block B — 오늘의 한 가지 카드

- 좌측: 작은 placeholder 이미지 박스(50×50pt).
- 우측 텍스트:
  - 최상단 muted 라벨 "오늘의 한 가지".
  - 타이틀(bold 12pt, 예: "십성이란 무엇인가?").
  - 메타 라인(muted 9pt, 예: "3분 · 초급").
- 카드 전체 탭 → `SajuRoute.lesson(id: featuredLessonId)` push. `featuredLessonId`는 provider
  에서 주입.
- 데이터: `SajuLearningPathProviding.featuredLesson: FeaturedLesson?` (id, title, durationLabel,
  levelLabel). nil인 경우 본 카드 자체를 숨긴다.

### Block C — 학습 경로 4-그리드

- 2-column × 2-row grid, 카드 간 8pt 간격. 카드 순서는 **고정** `[입문, 오행, 십성, 대운]`.
- 각 카드:
  - 타이틀(bold 12pt, 예: "입문").
  - 서브 메타(muted 9pt, 예: "7강").
  - 하단 진행률 바(높이 3pt). 채움 비율 = `progress`(0.0~1.0) × 100%.
  - 카드 전체 탭 → `SajuRoute.learn` push(전체 리스트의 해당 카테고리 필터로 진입하는 동작은
    WF4-06 책임이며, 본 슬라이스에서는 단순히 learn 라우트로 push).
- 데이터: `SajuLearningPathProviding.coursePaths: [CoursePath]`. CoursePath = `(name, lessonCount,
  averageMinutes?, progress)`. 4개 미만이면 비는 슬롯은 lock 표현(흐린 배경 + 진행률 0)으로
  렌더하되, 항상 4슬롯을 유지한다.

### Block D — 용어 사전 카드

- 좌측 작은 사각 placeholder(32×32pt, 글자 "A").
- 가운데 영역: 타이틀(bold 12pt) "용어 사전" + 서브(muted 10pt, 예: "명리학 용어 120개").
- 우측: `›` chevron.
- 카드 전체 탭 → 본 WF4 범위에서는 placeholder 동작(no-op + accessibility hint "준비중").
- 데이터: 정적 라벨 + `SajuLearningPathProviding.glossaryTermCount`(Int). count==0이면 "명리학
  용어"로만 표시.

### Block E — Disclaimer

- 사주 공부 섹션 가장 아래에 WF1/WF2/WF3와 **동일 컴포넌트**(`WDisclaimer` 또는 그 SwiftUI
  대응체) 재사용. 문구는 "본 앱은 학습·참고용이며 투자 권유가 아닙니다." 포함 필수.

### Block F — TabBar 표시

- 화면 하단에 공통 TabBar가 active=2 상태로 표시된다(WF4-01에서 구조는 이미 갖춰졌고, 본
  슬라이스에서 시각적 정상 동작을 검증).

### Mock 기본값(`MockSajuLearningPathProvider`, WF4-01과 동기화)

- `streakDays = 3`.
- `featuredLesson = (id: "L-TEN-001", title: "십성이란 무엇인가?", duration: "3분", level:
  "초급")`.
- `coursePaths = [(입문, 7강, 진행률 1.0), (오행, 5강, 0.6), (십성, 8강, 0.3), (대운, 6강,
  0.0)]`.
- `glossaryTermCount = 120`.

## Non-functional constraints

- iOS 17+ SwiftUI. 좌우 16pt padding, 카드 간 8pt 간격, 섹션 간 18pt 상단 마진.
- Dynamic Type Large까지 모든 텍스트 wrapping OK, 진행률 바 두께 유지.
- VoiceOver:
  - 연속 배지 = "연속 학습 {n}일".
  - 오늘의 한 가지 카드 = "오늘의 한 가지, {title}, {duration}, {level}".
  - 학습 경로 카드 = "{name} 코스, {lessonCount}강, 진행률 {percent}%".
  - 용어 사전 카드 = "용어 사전, 명리학 용어 {count}개".
- 모든 카드 hit target 44×44pt 이상.
- 색상/간격은 `DesignTokens` 재사용.

## Out of scope

- Header / TabBar 자체 구현 (WF4-01).
- 원국 카드 / 5 카테고리 카드 (WF4-02).
- 사주 공부 리스트 화면 본문(필터 pill, 진행 배너, 코스 셀, 추천 아티클) — WF4-06.
- 레슨 상세 화면 본문 — WF4-07.
- 오행/십성 상세 — WF4-04 / WF4-05.
- 용어 사전 상세 화면 — 본 WF4 범위 외(no-op).
- 연속 학습 일수의 실제 갱신 로직 — provider mock 값으로만 표시.
- Pull-to-refresh, 학습 데이터 원격 동기화.

## Acceptance criteria

각 항목은 unit/UI 테스트로 검증 가능해야 한다.

1. WF4-02 above-fold 마지막 요소 직후 본 섹션이 18pt 상단 마진과 함께 렌더된다(스크롤 위치
   검증).
2. "사주 공부하기" 헤더 우측에 `🔥 연속 {n}일` 배지가 `streakDays > 0`일 때만 표시된다.
   `streakDays = 0` mock 주입 시 배지가 숨겨진다.
3. "전체 ›" 보조 링크 탭 시 `SajuRoute.learn`이 NavigationStack path에 append된다.
4. `featuredLesson` mock 주입 시 "오늘의 한 가지" 카드에 title/duration/level이 정확히
   바인딩된다(`MockSajuLearningPathProvider` 기본값 기준 "십성이란 무엇인가?", "3분", "초급").
5. "오늘의 한 가지" 카드 탭 시 `SajuRoute.lesson(id: "L-TEN-001")`이 path에 append된다
   (associated value 검증).
6. `featuredLesson = nil` mock 주입 시 "오늘의 한 가지" 카드 전체가 숨겨지고 학습 경로
   그리드가 헤더 바로 아래로 밀어 올라온다.
7. 학습 경로 그리드는 항상 `[입문, 오행, 십성, 대운]` 순서로 4카드를 렌더한다(provider 배열
   순서와 무관하게 이름 매칭으로 정렬).
8. 각 학습 경로 카드의 진행률 바가 `progress` × 100% 너비로 표시된다(progress=1.0 → 100%,
   0.0 → 0%, 클램프됨).
9. 학습 경로 카드 탭 시 `SajuRoute.learn`이 path에 append된다(필터 동작은 WF4-06 책임).
10. 용어 사전 카드에 `glossaryTermCount`를 사용한 "명리학 용어 {N}개" 문구가 표시된다.
    count==0 mock 주입 시 "명리학 용어"로만 표시된다.
11. 용어 사전 카드 탭은 path를 변화시키지 않는다(no-op). VoiceOver hint에 "준비중"이
    노출된다.
12. Disclaimer가 사주 공부 섹션 가장 아래에 렌더되며 "본 앱은 학습·참고용이며 투자 권유가
    아닙니다." 문구가 항상 포함된다.
13. 화면 하단에 공통 TabBar가 active=2 상태로 가시적이다(WF4-03 기준 시점).
14. Dynamic Type XL에서 4-그리드 카드의 타이틀/서브가 wrapping되어 잘리지 않으며, 진행률
    바가 사라지거나 가려지지 않는다.
15. VoiceOver로 "오늘의 한 가지" 카드에 focus 시 "오늘의 한 가지, {title}, {duration},
    {level}" 형태로 읽힌다.
16. 모든 카드(오늘의 한 가지, 학습 경로 4개, 용어 사전)의 hit target이 44×44pt 이상을
    만족한다.
