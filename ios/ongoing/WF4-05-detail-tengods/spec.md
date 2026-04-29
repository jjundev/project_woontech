# WF4-05 — 십성 분석 상세 (사주 탭 카테고리 2번 목적지)

## User story / motivation

사주 탭 홈 카테고리 카드 "십성 분석" 탭 시 push되는 **십성 분석 상세** 화면. 십성 5그룹
(비겁/식상/재성/관성/인성) 분포를 막대 차트로 보여주고, 핵심 십성 Top 3 카드로 투자 함의를
풀어주며, 부재 십성에 대한 경고와 학습 진입점을 제공한다. above-fold 카테고리 카드, 다른
detail 화면(오행)과는 **완전히 독립된 provider**(`SajuTenGodsDetailProviding`)에서 데이터를
받는다.

## Functional requirements

- 새 View: `SajuTenGodsDetailView`. `SajuTabView`의 NavigationStack에서 `SajuRoute.tenGods`
  케이스의 목적지(WF4-01의 placeholder를 본 화면으로 교체).
- NavBar:
  - 타이틀 "십성 분석".
  - Back 버튼 — 탭 시 pop.
- 독립 provider `SajuTenGodsDetailProviding`(신규 정의, `Features/Saju/Detail/TenGods/` 하위):
  - `summaryHeadline: String` — 한줄 요약(예: "정재가 중심인 사주").
  - `summaryBody: String` — 보조 본문(예: "꼼꼼하고 안정을 추구하는 기질…").
  - `groups: [TenGodGroup]` — 길이 **고정 5**, 순서 `[비겁, 식상, 재성, 관성, 인성]`. 각 item
    `(name: String, han: String, meaning: String, items: [String], counts: [Int], total: Int,
    isCore: Bool, isAbsent: Bool)`. `items`는 항상 길이 2(예: 비견/겁재), `counts`도 길이 2로
    정렬 매칭.
  - `topThree: [CoreTenGod]` — 길이 **정확히 3**. 각 item `(name: String, han: String, count:
    Int, meaning: String, investImplication: String)`.
  - `absentWarning: AbsentWarning?` — `(groupTitle: String, items: String, copy: String)`. nil
    이면 경고 카드 자체 숨김.
  - `learnEntry: LearnEntry?` — `(title: String, durationLabel: String, levelLabel: String,
    lessonId: String)`. 탭 시 해당 lessonId로 `SajuRoute.lesson` push. nil이면 카드 숨김.
- `MockSajuTenGodsDetailProvider` 기본값(와이어프레임과 동일):
  - 그룹 5: 비겁(1), 식상(0, absent), 재성(2, core), 관성(1), 인성(1).
  - topThree: 정재(×2), 비견(×1), 정인(×1).
  - absentWarning: groupTitle "식상(식신·상관) 부재", copy "창의적 직관 매매보다 검증된 패턴
    매매가 내 성향에 맞아요".
  - learnEntry: title "십성이란 무엇인가요?", lessonId "L-TEN-001", duration "3분", level
    "초급".
- 레이아웃(수직 `ScrollView`, 좌우 16pt padding, 카드 간 10pt):
  1. **요약 카드** — muted "십성 요약" + headline(bold 13pt) + body(muted 10pt).
  2. **5그룹 분포 카드** — 섹션 라벨 "5그룹 분포" + 5행 각각:
     - 좌측: 한국어명(bold 12pt) + 한자(serif 9pt muted) + (선택) `핵심` 강조 배지(검정
       배경/흰 글씨, isCore일 때만).
     - 우측: 부재 시 빨강 "부재 ⚠", 그 외 muted "{total}/8".
     - 막대 바(높이 7pt). 채움 너비 = `total / 3` × 100%(상한 100% clamp). isAbsent는 채움
       색을 약한 톤으로.
     - 막대 아래 보조 라인: 좌측 의미(예: "주체성·동료"), 우측 표출 십성("비견" 등; counts>0
       만 ` · `로 join, 전무하면 "—").
  3. **나의 핵심 십성 카드** — 섹션 라벨 "나의 핵심 십성" + 내부 카드 3개. 첫 번째 카드는
     배경 강조(`gray`)와 더 진한 테두리. 각 카드:
     - 상단 좌측: 한국어명(bold 13pt) + 한자(serif 9pt muted).
     - 상단 우측: `×{count}` muted.
     - 본문: meaning(muted 10pt).
     - 하단 박스(`gray2` 배경): 💹 + investImplication(muted 9pt).
  4. **부재 십성 경고 카드**(존재 시) — 카드 테두리 빨강, 라벨 "주의 — 부재 십성"(빨강), 굵은
     groupTitle, 그 아래 연한 빨강 배경 박스에 copy 텍스트.
  5. **학습 유도 카드**(존재 시) — 좌측 큰 이모지 📚 + 우측 title(bold 12pt) + 메타 "{duration}
     레슨 · {level}" + 우측 `›`. 카드 탭 → `SajuRoute.lesson(id: lessonId)` push.
  6. **Disclaimer** — 동일 컴포넌트 재사용.

## Non-functional constraints

- iOS 17+ NavigationStack toolbar API 사용.
- Dynamic Type Large까지 모든 헤드라인/막대 라벨/topThree 본문/투자 함의 박스/경고 본문이
  wrapping OK.
- VoiceOver:
  - 그룹 행 = "{한국어명} {한자}, {meaning}, {total}점 8점 만점 중". isCore면 트레잇 "핵심",
    isAbsent면 "부재 경고".
  - topThree 카드 = "{한국어명} {한자}, {count}회, {meaning}. 투자 함의: {investImplication}".
  - absentWarning 카드 = "주의, 부재 십성, {groupTitle}. {copy}".
  - learnEntry 카드 = "레슨 진입, {title}, {duration}, {level}".
- 색상/간격은 `DesignTokens` 재사용. 핵심 배지/부재 빨강은 토큰 키로 분리.

## Out of scope

- 사주 탭 카테고리 카드 (WF4-02).
- 오행 분포 상세 (WF4-04) 및 다른 detail 화면.
- 학습 리스트 (WF4-06).
- 레슨 상세 본문 (WF4-07) — 본 슬라이스에서는 lesson 라우트 push까지만 검증.
- 실제 십성 계산 로직 — 전부 mock.
- 그룹별 sub-route(예: 재성만 더 깊게 보는 화면).
- topThree의 카드 탭 동작(현재 정의 없음, no-op).
- 공유/저장/북마크.

## Acceptance criteria

각 항목은 unit/UI 테스트로 검증 가능해야 한다.

1. WF4-02의 "십성 분석" 카드 탭 시 `SajuTenGodsDetailView`가 push된다.
2. NavBar 타이틀은 "십성 분석"이고, Back 버튼 탭 시 pop되어 사주 탭 홈으로 복귀한다.
3. 요약 카드의 headline과 body는 provider의 `summaryHeadline`, `summaryBody`를 그대로
   바인딩한다.
4. 5그룹 분포 카드의 행은 항상 `[비겁, 식상, 재성, 관성, 인성]` 순서로 5개 렌더된다(provider
   배열 순서와 무관하게 name 매칭으로 정렬).
5. `isCore = true`인 그룹(예: 재성)은 행 좌측 라벨 영역에 검정 배경 "핵심" 배지가 표시되고,
   다른 그룹에서는 표시되지 않는다.
6. `isAbsent = true`인 그룹은 우측 메타가 빨강 "부재 ⚠"로 표시되고, 막대 채움이 약한 톤(또는
   0% 너비)으로 렌더된다.
7. 막대 채움 너비는 `min(total / 3, 1.0) × 100%`를 정확히 따른다(total=2 → 약 66.7%, total=3
   이상 → 100%).
8. 그룹 행 보조 라인 우측의 표출 십성 텍스트는 `counts[i] > 0` 인 items만 ` · `로 join 되어
   표시된다(전부 0이면 "—").
9. `groups` 배열 길이가 5가 아니거나 임의 item의 `items`/`counts` 길이가 2가 아니면
   precondition 실패가 발생한다(테스트로 검증).
10. 핵심 십성 카드 영역에는 항상 3개 카드가 렌더된다(`topThree.count != 3` 시 precondition
    실패). 첫 번째 카드는 배경/테두리 강조가 시각적으로 구분된다.
11. 각 핵심 십성 카드의 `name`, `han`, `count`, `meaning`, `investImplication`이 정확히
    바인딩된다(`MockSajuTenGodsDetailProvider` 기본값 기준 정재 ×2, 비견 ×1, 정인 ×1).
12. `absentWarning != nil` 시 경고 카드가 핵심 십성 카드 다음에 렌더되며, 카드 테두리가
    빨강 토큰으로 적용되고 본문 박스 배경이 연한 빨강으로 표시된다.
13. `absentWarning = nil` 시 경고 카드 전체가 숨겨진다.
14. `learnEntry != nil` 시 학습 유도 카드가 렌더되고, 카드 탭 시 `SajuRoute.lesson(id:
    learnEntry.lessonId)`가 NavigationStack path에 append된다(`MockSajuTenGodsDetailProvider`
    기본값 기준 lessonId="L-TEN-001").
15. `learnEntry = nil` 시 학습 유도 카드 전체가 숨겨진다.
16. Disclaimer 문구가 화면 최하단에 렌더되며 WF1/WF2/WF3와 동일 문구를 포함한다.
17. `SajuTenGodsDetailProviding`은 `SajuCategoriesProviding` 및 `SajuElementsDetailProviding`
    과 별개의 프로토콜이며, 어느 한쪽 구현체로 다른 쪽을 대입할 수 없다(컴파일 타임 분리).
18. VoiceOver focus 순서: NavBar 타이틀 → 요약 → 5그룹(비겁→…→인성) → 핵심 Top3 카드 →
    부재 경고(있을 때) → 학습 유도(있을 때) → Disclaimer.
19. Dynamic Type XL에서 핵심 카드의 investImplication 박스와 경고 카드의 copy가 wrapping되어
    잘리지 않는다.
