# Implementation Checklist — WF3-05 이벤트 상세

## Requirements (from spec)

- [ ] R1: `EventDetailView(event: WeeklyEvent)` 뷰 신규 생성; `HomeRoute.event(event)` 목적지로 연결
- [ ] R2: NavBar — 타이틀 "이벤트 상세", Back(자동, `@Environment(\.dismiss)`), 우측 "공유" 텍스트 버튼 → `onShareTap` placeholder
- [ ] R3: `EventDetailProviding` 프로토콜 + `EventDetailContent` struct(5프로퍼티) 신규 생성
- [ ] R4: `MockEventDetailProvider` — 와이어프레임 "대운 전환" 기본값 + 사용자 정의 init 주입 지원
- [ ] R5: 타이틀 카드 — `icon`, `title`, `oneLiner`, `ddayDate`, `dday` 렌더; `badge` nil → pill 숨김, non-nil → pill 렌더
- [ ] R6: "이 이벤트가 의미하는 것" 섹션 — 섹션 라벨 + `EventDetailProviding.content(for:).meaning` 본문
- [ ] R7: "내 사주와의 관계" 섹션 — 회색 박스 내 `sajuRelationFormula`(bold) + `sajuRelationNote`(caption)
- [ ] R8: "💹 투자 관점" 섹션 — `investPerspectives` bullet 리스트; 배열 비면 섹션 전체(헤더 포함) 숨김
- [ ] R9: 액션 버튼 3개 (높이 38pt, 폰트 11pt) — Bell·Calendar·Learn(learnCTAText, primary 스타일), 세로 VStack
- [ ] R10: `DisclaimerView()` — ScrollView 최하단 요소로 배치
- [ ] R11: `WeeklyEvent` 타입 신규 도입 없이 WF3-03 정의 그대로 import 사용
- [ ] R12: Dynamic Type Large — 본문 및 bullet 모두 `lineLimit(nil)` + `fixedSize(horizontal: false, vertical: true)` wrapping 보장
- [ ] R13: VoiceOver 순서 — 전체 뷰를 `VStack { NavBarHStack; ScrollView { … } }` 로 구성해 NavBar → 타이틀 카드 → 의미 → 사주 관계 → 투자 관점 → 액션 버튼 3개 → disclaimer 순서 보장; 섹션 컨테이너 3개에 `.accessibilityElement(children: .contain)` 적용; 액션 버튼 컨테이너 미적용(개별 포커스)

---

## Implementation Steps

- [ ] S1: `EventDetailProviding.swift` 신규 생성 (`Features/Home/Detail/Event/` 폴더) — `EventDetailContent` struct 정의 (meaning, sajuRelationFormula, sajuRelationNote, investPerspectives, learnCTAText)
- [ ] S2: 같은 파일 — `EventDetailProviding` 프로토콜(`func content(for:) -> EventDetailContent`) + `MockEventDetailProvider`(기본값 + 커스텀 init) 정의
- [ ] S3: `EventDetailView.swift` 신규 생성 — `VStack { NavBarHStack; ScrollView { … } }` 스켈레톤, NavBar(Back `chevron.left` / 타이틀 "이벤트 상세" / 공유 텍스트 버튼) + accessibilityIdentifier 세 곳
- [ ] S4: 타이틀 카드 섹션 — icon + title(bold) + oneLiner; 회색 박스(날짜 + D-day 텍스트 + badge pill 조건부); `accessibilityIdentifier: "EventDetailTitleCard"`
- [ ] S5: "이 이벤트가 의미하는 것" 섹션 — 섹션 라벨 + `content.meaning` 본문; `lineLimit(nil)` + `fixedSize`; `.accessibilityElement(children: .contain)`; identifiers `EventDetailMeaningSection` / `EventDetailMeaningText`
- [ ] S6: "내 사주와의 관계" 섹션 — 회색 박스; `sajuRelationFormula`(bold, identifier `EventDetailSajuFormula`) + `sajuRelationNote`(caption, identifier `EventDetailSajuNote`); `.accessibilityElement(children: .contain)`; identifier `EventDetailSajuSection`
- [ ] S7: "💹 투자 관점" 섹션 — `investPerspectives.isEmpty` 시 전체 숨김; `ForEach` bullet(identifier `EventDetailInvestBullet_\(index)`); `lineLimit(nil)` + `fixedSize`; `.accessibilityElement(children: .contain)`; identifier `EventDetailInvestSection`
- [ ] S8: 액션 버튼 3개 — `.frame(height: 38)` / `.font(.system(size: 11))`; Bell(`EventDetailBellButton` → `onBellReminderTap`), Calendar(`EventDetailCalendarButton` → `onAddToCalendarTap`), Learn primary 스타일(`EventDetailLearnButton` → `onLearnTap`, 텍스트 = `content.learnCTAText`); 컨테이너 identifier `EventDetailActionButtons`
- [ ] S9: `DisclaimerView()` — ScrollView 내 최하단 배치
- [ ] S9a: VoiceOver — VStack 레이아웃으로 순서 자연 보장; ZStack/overlay NavBar 금지; 섹션 컨테이너 3개에 `.accessibilityElement(children: .contain)` 적용(S5·S6·S7); 액션 버튼 컨테이너에 미적용
- [ ] S10: `HomeDependencies.swift` 수정 — `var eventDetail: any EventDetailProviding = MockEventDetailProvider()` 추가; `init` 파라미터 추가(기본값, 기존 호출부 비파괴)
- [ ] S11: `HomeDashboardView.swift` 수정 — `.event(let event)` 케이스에 `EventDetailView(event:provider:onShareTap:onBellReminderTap:onAddToCalendarTap:onLearnTap:)` 연결; `@State` spy 카운터 4개(opacity-0 overlay staticText로 노출); 런치 인수 처리(`-mockCustomMeaning`, `-mockCustomLearnCTA`, `-mockCustomSajuFormula`, `-mockEmptyInvestPerspectives`)
- [ ] S12: `HomeRouteDestinations.swift` 수정 — `EventPlaceholderView` @available deprecated 마킹

---

## Tests

### Unit Tests (`WoontechTests/Home/EventDetailViewTests.swift`)

- [ ] T1 (unit — U1): `MockEventDetailProvider()` 기본값 — meaning/sajuRelationFormula/sajuRelationNote/learnCTAText 와이어프레임 문자열과 일치
- [ ] T2 (unit — U2): `MockEventDetailProvider()` 기본값 — investPerspectives 배열 길이 3, 각 항목 내용 검증
- [ ] T3 (unit — U3): 사용자 정의 meaning 주입 → `content(for:).meaning` 반환값 일치
- [ ] T4 (unit — U4): 사용자 정의 investPerspectives 주입 → 배열 길이·내용 일치
- [ ] T5 (unit — U5): 사용자 정의 sajuRelationFormula / sajuRelationNote 주입 → 반환값 검증
- [ ] T6 (unit — U6): 사용자 정의 learnCTAText 주입 → 반환값 검증
- [ ] T7 (unit — U7): investPerspectives 빈 배열 주입 → `isEmpty == true`
- [ ] T8 (unit — U8): learnCTAText 기본값이 비어 있지 않음
- [ ] T9 (unit — U9): `WeeklyEvent.badge == nil` 분기 로직 검증
- [ ] T10 (unit — U10): `WeeklyEvent.badge != nil` badge 값 검증
- [ ] T11 (unit — U11): `EventDetailView` 생성 시 crash 없음 (smoke)

### UI Tests (`WoontechUITests/Home/EventDetailUITests.swift`)

- [ ] T12 (ui — UI1): `-openHome` + `HomeNavPushEvent` 탭 → `EventDetailTitle` 존재 (push 성공) [AC-1]
- [ ] T13 (ui — UI2): `EventCardView` 직접 탭 → `EventDetailTitle` 나타남 (카드 경유 진입) [AC-1]
- [ ] T14 (ui — UI3): NavBar 타이틀 label == "이벤트 상세" [AC-2]
- [ ] T15 (ui — UI4): `EventDetailBackButton` + `EventDetailShareButton` 존재 [AC-2]
- [ ] T16 (ui — UI5): 타이틀 카드에 event.icon / title / oneLiner / ddayDate / D-day 텍스트 포함 [AC-2]
- [ ] T17 (ui — UI6): badge nil 이벤트 → badge pill 미존재; badge non-nil → badge pill 존재 [AC-2]
- [ ] T18 (ui — UI7): `EventDetailMeaningSection` 존재; `EventDetailMeaningText` 기본 mock meaning 포함 [AC-3]
- [ ] T19 (ui — UI8): `EventDetailSajuFormula` / `EventDetailSajuNote` 기본 mock 문자열 확인 [AC-4]
- [ ] T20 (ui — UI9): 기본 mock — `EventDetailInvestBullet_0/1/2` 모두 존재 [AC-5]
- [ ] T21 (ui — UI10): `-mockEmptyInvestPerspectives` 런치 인수 → `EventDetailInvestSection` 미존재 [AC-5]
- [ ] T22 (ui — UI11): `EventDetailActionButtons` 내 Bell/Calendar/Learn 버튼 3개 존재 [AC-6]
- [ ] T23 (ui — UI12): `EventDetailLearnButton` label == 기본 mock learnCTAText [AC-6]
- [ ] T24 (ui — UI13): `EventDetailBellButton` 탭 → spy 카운터(`EventDetailBellTapCount`) 1 증가 [AC-7]
- [ ] T25 (ui — UI14): `EventDetailCalendarButton` 탭 → spy 카운터(`EventDetailCalendarTapCount`) 1 증가 [AC-8]
- [ ] T26 (ui — UI15): `EventDetailLearnButton` 탭 → spy 카운터(`EventDetailLearnTapCount`) 1 증가 [AC-9]
- [ ] T27 (ui — UI16): `EventDetailShareButton` 탭 → spy 카운터(`EventDetailShareTapCount`) 1 증가 [AC-10]
- [ ] T28 (ui — UI17): `EventDetailBackButton` 탭 → `HomeDashboardRoot` 복귀 [AC-11]
- [ ] T29 (ui — UI18): 스크롤 최하단 `DisclaimerText` 존재 [AC-12]
- [ ] T30 (ui — UI19): `UIContentSizeCategoryOverride = UICTContentSizeCategoryAccessibilityXL` 환경 — `EventDetailMeaningText` frame.height > 0이며 "…" 미포함; `EventDetailInvestBullet_0` 동일 검증 [AC-14]
- [ ] T31 (ui — UI20): `-mockCustomMeaning "커스텀의미텍스트"` + `-mockCustomLearnCTA "커스텀CTA텍스트"` 런치 인수 → `EventDetailView` 진입 후 `EventDetailMeaningText`에 "커스텀의미텍스트" 포함, `EventDetailLearnButton` label == "커스텀CTA텍스트" (provider → 뷰 바인딩 엔드-투-엔드) [AC-13]
- [ ] T32 (ui — UI21): `-mockCustomSajuFormula "커스텀공식"` 런치 인수 → `EventDetailSajuFormula` label에 "커스텀공식" 포함 [AC-13]
