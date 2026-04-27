# WF4-02 — 사주 탭 above-the-fold (원국 카드 + 5 카테고리)

## User story / motivation

사주 탭 진입 시 사용자가 가장 먼저 보는 두 블록을 구현한다. ① **내 원국 4주 카드**(時/日/月/年
4기둥 grid + 일간 강조 + 일간 한줄 해석), ② **"내 사주 자세히" 섹션의 5개 카테고리 카드**
(오행 분포 / 십성 분석 / 대운·세운 / 합충형파 / 용신·희신). 각 카테고리 카드는 탭 시
WF4-01에서 선언된 `SajuRoute`로 push되어 본인의 사주를 더 깊게 탐색하도록 유도한다.
이 슬라이스는 WF4-01에서 시그니처만 선언된 `UserSajuOriginProviding`·`SajuCategoriesProviding`
의 mock 구현과 데이터 바인딩을 완성한다.

## Functional requirements

- `SajuTabView`의 컨텐츠 슬롯 상단에 본 슬라이스 두 블록이 렌더된다(WF4-01의 "준비중"
  placeholder 제거). 하단의 학습 섹션/Disclaimer는 WF4-03 범위.

### Block A — 내 원국 카드

- 카드 상단 좌측 라벨 "내 사주 원국"(작은 muted), 우측 보조 링크 "전체 보기 ›"(muted).
- 4-column grid로 4개 기둥 셀을 렌더한다. 순서는 **고정** `[時, 日, 月, 年]`.
- 각 기둥 셀:
  - 최상단: 기둥 이름(時/日/月/年) — 작은 muted.
  - 중간: 천간(天干) 박스 — 큰 한자 문자(volume 14pt 권장). **일간(日의 천간)** 셀은 배경
    강조(예: `WF.gray`/토큰의 강조 배경).
  - 하단: 지지(地支) 박스 — 큰 한자 문자.
- 카드 하단에 일간 해석 한줄 박스(배경 강조): `dayMasterLine` 텍스트(예: "일간 丙火 · 양의
  불 — 따뜻함, 표현력, 리더십"). 여러 줄 wrapping 허용.
- 데이터: `UserSajuOriginProviding.pillars`(길이 4, 순서 時→日→月→年), `dayMasterLine`.
  pillars 길이가 4가 아니면 precondition 실패(컴파일/런타임 보장).
- "전체 보기 ›" 탭 → `SajuRoute.elements` push **하지 않는다**(원국 자체 상세는 본 WF4
  범위 외). 본 슬라이스에서는 시각만 표시하고 동작은 no-op + accessibility hint "준비중".

### Block B — "내 사주 자세히" 섹션 (5개 카테고리 카드)

- 섹션 헤더 텍스트 "내 사주 자세히" (bold 12pt 권장).
- 카드 리스트는 항상 **5개 고정 순서**로 렌더된다: `[오행 분포, 십성 분석, 대운 · 세운,
  합충형파, 용신 · 희신]`. 데이터 누락이 있더라도 5슬롯을 유지(빈 카드는 "데이터 없음"
  placeholder).
- 각 카테고리 카드 컴포넌트:
  - 좌측 텍스트 영역: 타이틀(예: "오행 분포") + 1줄 요약(`summary` 텍스트, muted) + (선택)
    badge(예: "부족: 水", "전환기", "핵심").
  - 우측 영역: 우측 정렬 `›` chevron + 그 아래 작은 밑줄 텍스트 "근거 보기".
  - 카드 전체(좌/우 영역 포함) 탭 → 해당 카테고리의 라우트 push.
  - 우측 "근거 보기" 영역 단독 탭 → 본 슬라이스에서는 카드 push와 동일 동작(별도 근거
    화면은 본 WF4 범위 외). 탭 영역은 단일 hit-test로 통합한다(자식이 가로채지 않음).
- 카테고리별 라우트 매핑(고정):
  - `오행 분포` → `SajuRoute.elements`
  - `십성 분석` → `SajuRoute.tenGods`
  - `대운 · 세운` → `SajuRoute.daewoonPlaceholder`
  - `합충형파` → `SajuRoute.hapchungPlaceholder`
  - `용신 · 희신` → `SajuRoute.yongsinPlaceholder`
- 데이터: `SajuCategoriesProviding`이 5개 슬롯 각각의 `summary: String`과 `badge: String?`을
  반환한다.
- `MockUserSajuOriginProvider` 기본값: 와이어프레임 예시(時庚申 / 日丙午 / 月辛卯 / 年庚午,
  dayMasterLine "일간 丙火 · 양의 불 — 따뜻함, 표현력, 리더십").
- `MockSajuCategoriesProvider` 기본값:
  - 오행: summary "火 3 · 金 2 · 木 1 · 水 0 · 土 2", badge "부족: 水".
  - 십성: summary "비견·식신·정재 강함", badge nil.
  - 대운: summary "현재 丁巳 대운 (32~41)", badge "전환기".
  - 합충: summary "일지-시지 合, 월지 沖", badge nil.
  - 용신: summary "水 용신, 金 희신", badge nil.

## Non-functional constraints

- iOS 17+ SwiftUI. 16pt 좌우 padding, 카드 간 8pt 간격.
- Dynamic Type Large까지 원국 셀의 한자, 일간 한줄, 카테고리 카드 요약/badge 모두 wrapping
  되며 잘리지 않는다.
- VoiceOver:
  - 원국 카드 셀 = "{기둥명}, 천간 {한자}, 지지 {한자}". 일간 셀은 추가로 트레잇 "강조".
  - 일간 한줄 박스 = `dayMasterLine` 전문.
  - 카테고리 카드 = "{타이틀}, {summary}". badge 존재 시 끝에 "{badge} 표시".
- 카테고리 카드 hit target은 44×44pt 이상.
- 색상/간격은 `DesignTokens` 재사용. 일간 강조 배경은 토큰 키로 정의.

## Out of scope

- Header / TabBar / NavigationStack / 라우트 enum (WF4-01에서 완료).
- 사주 공부하기 섹션 전체(연속 배지, 오늘의 한 가지, 학습 경로 그리드, 용어 사전,
  Disclaimer) — WF4-03.
- 오행 분포 상세 화면 본문 — WF4-04.
- 십성 분석 상세 화면 본문 — WF4-05.
- 사주 공부 리스트 / 레슨 상세 — WF4-06 / WF4-07.
- 대운·세운 / 합충형파 / 용신·희신 상세 화면 — placeholder route push만 수행, 본 WF4
  범위 외.
- "근거 보기" 별도 화면 — 본 WF4 범위 외(현재는 카테고리 라우트와 동일 동작).
- 원국 카드 "전체 보기" 별도 화면 — 본 WF4 범위 외(no-op).
- Pull-to-refresh / 실시간 데이터 갱신.

## Acceptance criteria

각 항목은 unit/UI 테스트로 검증 가능해야 한다.

1. `SajuTabView` 컨텐츠 슬롯 최상단에 원국 카드, 그 아래 "내 사주 자세히" 섹션 헤더와 5개
   카테고리 카드 순으로 렌더된다.
2. 원국 카드의 4기둥 셀은 항상 `[時, 日, 月, 年]` 순서로 표시된다(provider 데이터 순서와
   무관하게 라벨 매칭으로 정렬).
3. `MockUserSajuOriginProvider` 기본값 주입 시 4기둥 셀에 각각 `時庚申 / 日丙午 / 月辛卯 /
   年庚午`의 천간/지지가 표시된다.
4. 일간(日의 천간) 셀의 배경이 강조 토큰으로 채색되며, 다른 셀의 배경과 시각적으로 구분된다
   (UI 스냅샷 또는 색상 트레잇 검증).
5. 일간 한줄 박스에 `UserSajuOriginProviding.dayMasterLine` 값이 그대로 렌더된다(예: "일간
   丙火 · 양의 불 — 따뜻함, 표현력, 리더십").
6. `pillars` 배열 길이가 4가 아닌 mock을 주입하면 precondition 실패가 명시적으로 발생한다
   (테스트가 의도적으로 실패하거나 명시 fatalError).
7. "내 사주 자세히" 섹션은 항상 `[오행 분포, 십성 분석, 대운 · 세운, 합충형파, 용신 · 희신]`
   순서로 5개 카드를 렌더한다(슬롯 누락 mock 주입 시에도 5슬롯 유지, 누락 슬롯은 "데이터
   없음" placeholder).
8. 각 카테고리 카드는 provider의 해당 슬롯 `summary`와 `badge`(있을 때)를 정확히 바인딩한다
   (badge가 nil이면 badge UI 자체가 숨겨진다).
9. "오행 분포" 카드 탭 시 `SajuRoute.elements`가 NavigationStack path에 append된다.
10. "십성 분석" 카드 탭 시 `SajuRoute.tenGods`가 path에 append된다.
11. "대운 · 세운" 카드 탭 시 `daewoonPlaceholder`가 path에 append된다.
12. "합충형파" 카드 탭 시 `hapchungPlaceholder`가 path에 append된다.
13. "용신 · 희신" 카드 탭 시 `yongsinPlaceholder`가 path에 append된다.
14. 카테고리 카드의 "근거 보기" 영역만 탭해도 카드 전체 탭과 동일하게 해당 라우트가 push
    된다(단일 hit-test 검증).
15. 원국 카드의 "전체 보기 ›" 영역 탭은 path를 변화시키지 않는다(no-op). VoiceOver hint에
    "준비중"이 노출된다.
16. Dynamic Type XL에서 카테고리 카드의 summary/badge가 wrapping되어 잘리지 않는다.
17. VoiceOver focus가 일간 셀에 닿으면 트레잇 "강조"와 함께 "{기둥명}, 천간 {한자}, 지지
    {한자}"가 읽힌다.
18. 5개 카테고리 카드 각각의 hit target이 44×44pt 이상을 만족한다(accessibility inspector
    또는 hit-test 검증).
