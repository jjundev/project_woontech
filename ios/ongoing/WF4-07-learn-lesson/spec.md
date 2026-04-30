# WF4-07 — 레슨 상세 (학습 경험)

## User story / motivation

`SajuRoute.lesson(id:)`로 push되는 **레슨 상세** 화면. 사주 공부 리스트(WF4-06), 사주 탭
홈의 "오늘의 한 가지"(WF4-03), 십성 분석 상세의 학습 유도 카드(WF4-05) 등 다양한 진입점에서
도달한다. 레슨의 위치(N/M)를 진행 바로 보여주고, 본문 개념 박스 + 다이어그램 placeholder +
인라인 퀴즈를 통해 짧은 시간 안에 한 가지 개념을 학습하도록 한다. 인라인 퀴즈는 즉시 피드백
(정답 선택 강조)을 통해 몰입도를 높이고, 하단 "다음 강의" CTA로 학습 흐름을 이어간다.

## Functional requirements

- 새 View: `SajuLessonView`. `SajuTabView`의 NavigationStack에서 `SajuRoute.lesson(id:)` 케이스의
  목적지(WF4-01의 placeholder를 본 화면으로 교체).
- 화면 진입 시 NavigationStack에서 전달된 `id` 값으로 provider에 콘텐츠를 요청한다.
- NavBar:
  - 타이틀: "{레슨 번호}강 · {레슨 제목}" (예: "3강 · 오행의 의미"). 길이 초과 시 자동
    말줄임.
  - Back 버튼 — 탭 시 pop.
  - 우측 액션 영역: muted 텍스트 "{currentIndex}/{totalCount}" (예: "3/7").
- 헤더 직하단 가로 진행 바(높이 3pt):
  - 채움 너비 = `currentIndex / totalCount` × 100%(상한 100% clamp).
- 데이터: `SajuLessonProviding`(WF4-01에서 시그니처만 선언, 본 슬라이스에서 본격 사용):
  - `func lesson(id: String) -> Lesson` — 동기 fetch(테스트 가능). id가 알려지지 않은 경우
    fallback "준비중" lesson을 반환(에러 화면은 별도로 만들지 않는다).
  - `Lesson` = `(id, number, title, currentIndex, totalCount, sectionLabel, headline, conceptBox,
    diagramPlaceholderLabel, quiz)`.
  - `Quiz` = `(label: String, question: String, choices: [Choice], correctIndex: Int)`. choices
    길이는 **고정 4**.
  - `Choice` = `(symbol: String)`.
  - `nextLessonId: String?` — 다음 강의 id. nil이면 마지막 강의.
- `MockSajuLessonProvider` 기본값(와이어프레임 "3강 · 오행의 의미"와 동일):
  - id "L-OH-003", number 3, title "오행의 의미", currentIndex 3, totalCount 7,
    sectionLabel "기본 개념", headline "오행이란?".
  - conceptBox: "오행은 木·火·土·金·水의 다섯 요소로, 세상 모든 것을 다섯 기운의 흐름으로
    설명하는 명리학의 기본 틀입니다.".
  - diagramPlaceholderLabel: "상생·상극 다이어그램".
  - quiz: label "간단 체크", question "水를 생(生)하는 오행은?", choices `[木, 火, 金, 土]`,
    correctIndex 2(즉 金).
  - nextLessonId "L-OH-004".
- 레이아웃(수직 `ScrollView`, 좌우 18pt padding):
  1. 상단 muted 9pt `sectionLabel`(예: "기본 개념"). 그 아래 6pt 마진.
  2. headline(bold 17pt).
  3. 14pt 마진 후 **개념 박스** — 배경 강조(`gray` 토큰), 16pt padding, radius 8pt, 본문 11pt.
  4. 14pt 마진 후 **다이어그램 placeholder** — 가로 200pt × 세로 140pt 박스, 중앙 정렬, 라벨
     `diagramPlaceholderLabel` 표시.
  5. 16pt 마진 후 **인라인 퀴즈 카드** — 카드 padding 14pt:
     - 헤더: 작은 사각 라벨 박스(테두리 + "Q") + muted 라벨(`quiz.label`).
     - question(bold 12pt).
     - 4지선다 옵션 박스 4개(세로 stack, 6pt 간격). 각 옵션 박스는 좌측에 `symbol` 텍스트.
     - **선택 전 상태**: 모든 옵션 박스 회색 테두리 + 흰 배경 + regular weight.
     - **사용자가 옵션을 탭하면**:
       - 선택한 옵션이 정답(`index == correctIndex`)이면: 해당 옵션 박스만 진한 테두리(`ink`
         토큰) + 강조 배경(`gray`) + bold weight로 전환된다. 다른 옵션은 회색 테두리 유지.
       - 오답이면: 선택한 옵션 박스를 빨강 테두리 + 연한 빨강 배경으로 전환하고, **정답 옵션
         박스에도** 진한 테두리(`ink`) + 강조 배경(`gray`)을 함께 표시한다.
     - 한 번이라도 선택한 후에는 다른 옵션 탭이 무시된다(재선택 불가; 시각 상태 유지).
- 하단 고정 영역(safe area 위):
  - 상단 1pt 구분선(`line3`), 흰 배경.
  - **"다음 강의" primary CTA**:
    - 사용자가 정답을 선택한 후에만 활성화(이전에는 비활성, dim).
    - `nextLessonId == nil` 이면 라벨을 "학습 완료"로 바꾸고, 탭 시 NavigationStack을 pop해
      WF4-06(공부 리스트)로 복귀한다.
    - `nextLessonId != nil` 이면 탭 시 현재 화면을 같은 NavigationStack에서 `SajuRoute.lesson(
      id: nextLessonId)`로 **replace**(이전 레슨 화면이 stack에 남지 않도록 path 마지막
      element를 교체).
- 화면 진입 시 스크롤 위치는 항상 최상단(`sectionLabel`).

## Non-functional constraints

- iOS 17+ NavigationStack toolbar API.
- Dynamic Type Large까지 headline / conceptBox / question / 옵션 텍스트 모두 wrapping OK.
  진행 바 두께(3pt)와 옵션 박스 hit area(44pt)는 유지.
- VoiceOver:
  - NavBar 타이틀 = "{number}강, {title}". 우측 = "현재 {currentIndex}강, 총 {totalCount}강".
  - 진행 바 = "진행률 {percent}%".
  - 개념 박스 = headline 다음에 conceptBox 본문 그대로 읽힘.
  - 다이어그램 placeholder = "다이어그램 자리, {label}".
  - 퀴즈 = "퀴즈, {question}". 옵션 = "{symbol}". 정답 선택 후 정답 옵션 트레잇 "정답"(빨강
    오답 선택 후 그 옵션 트레잇 "오답").
  - 선택 후 정답 안내는 별도 `announcement` 없이 시각/트레잇만으로 전달(스피커/사용자 옵션을
    직접 다시 focus).
- 색상은 `DesignTokens` 재사용. 정답 강조와 오답 빨강 배경/테두리는 토큰 키로 분리.

## Out of scope

- 사주 탭 홈 / 카테고리 / 학습 섹션 — WF4-02 / WF4-03.
- 오행 / 십성 상세 — WF4-04 / WF4-05.
- 사주 공부 리스트 — WF4-06.
- 다중 페이지 레슨(한 강의 안에서 여러 페이지 슬라이드) — 이번 슬라이스는 단일 스크롤 페이지
  레슨만 다룬다.
- 정답/오답 통계 영속화·서버 동기화.
- 레슨 완료 시 코스 진행률 갱신 로직(provider mock 값만 표시).
- 다이어그램 placeholder의 실제 다이어그램 렌더(이미지/SVG 자산은 후속).
- 정답 해설 본문(설명 modal/expand) — 현재는 시각 강조만.
- "이전 강의" 버튼 / 좌우 스와이프 네비게이션.

## Acceptance criteria

각 항목은 unit/UI 테스트로 검증 가능해야 한다.

1. WF4-06 / WF4-03 / WF4-05 어느 진입점에서든 `SajuRoute.lesson(id:)`로 push 시
   `SajuLessonView`가 렌더된다.
2. NavBar 타이틀에 `"{number}강 · {title}"` 형식이 표시된다(`MockSajuLessonProvider` 기본값
   기준 "3강 · 오행의 의미"). 길이 초과 시 말줄임 처리된다.
3. NavBar 우측에 muted "{currentIndex}/{totalCount}" 형식 텍스트가 표시된다("3/7").
4. 진행 바 채움 너비 = `min(currentIndex / totalCount, 1.0) × 100%` 비율을 정확히 따른다
   (3/7 → 약 42.857%).
5. `currentIndex > totalCount` 인 mock 주입 시 진행 바는 100%로 clamp되어 렌더된다.
6. 화면 본문에 sectionLabel, headline, conceptBox, diagramPlaceholderLabel이 provider 값
   그대로 바인딩된다.
7. 인라인 퀴즈의 옵션 박스는 항상 4개이며 `quiz.choices` 순서를 따른다(`choices` 길이가 4가
   아닌 mock 주입 시 precondition 실패).
8. 선택 전 모든 옵션 박스가 회색 테두리 + 흰 배경이며, "다음 강의" CTA는 비활성 상태이다.
9. 정답 옵션을 처음으로 탭하면 해당 옵션만 진한 테두리(`ink`) + 강조 배경으로 전환되고
   다른 옵션은 회색 상태를 유지한다. "다음 강의" CTA가 활성화된다.
10. 오답 옵션을 처음으로 탭하면 해당 옵션이 빨강 테두리 + 연한 빨강 배경으로 전환되고, 정답
    옵션도 동시에 진한 테두리 + 강조 배경으로 함께 표시된다. "다음 강의" CTA가 활성화된다.
11. 한 번 옵션을 선택한 후 다른 옵션을 다시 탭해도 옵션 상태와 CTA 상태는 변하지 않는다(재
    선택 불가).
12. `nextLessonId != nil` 인 상태에서 정답/오답 선택 후 "다음 강의" CTA 탭 시, NavigationStack
    path의 마지막 element가 `SajuRoute.lesson(id: nextLessonId)`로 **교체**된다(이전 레슨이
    stack에 남지 않음 — Back 누르면 곧장 WF4-06로 복귀).
13. `nextLessonId == nil` 인 mock 주입 시 CTA 라벨이 "학습 완료"로 표시되며, 탭 시 stack이
    pop되어 WF4-06으로 복귀한다.
14. 알려지지 않은 `id`로 push 시 fallback "준비중" lesson이 렌더되며 앱이 크래시되지 않는다
    (NavBar 타이틀에 "준비중" 류 표기, 퀴즈 영역은 비활성/숨김 처리).
15. `SajuLessonProviding`은 `SajuLearningPathProviding`과 별개의 프로토콜이며, 한쪽 구현체로
    다른 쪽을 대입할 수 없다(컴파일 타임 분리).
16. VoiceOver focus 순서: NavBar 타이틀 → 진행률 → sectionLabel → headline → conceptBox →
    다이어그램 placeholder → 퀴즈 헤더 → question → 옵션 1~4 → "다음 강의" CTA.
17. 옵션 박스 hit target이 44×44pt 이상이고, "다음 강의" CTA hit target도 44×44pt 이상이다.
18. Dynamic Type XL에서 headline / conceptBox / question / 옵션 텍스트가 모두 wrapping되어
    잘리지 않으며, 진행 바 두께(3pt)와 옵션 박스 좌측 hit area가 유지된다.
