# WF3-03 홈 below-the-fold 구현 계획 (v1)

## 1. Goal

HomeDashboardView의 ScrollView에 Section 7 (이번 주 흐름), Section 8 (공유 훅), Section 9 (PRO 티저), Disclaimer를 추가하여 완전한 below-the-fold 화면을 구성한다. 동시에 WeeklyEventsProviding 프로토콜을 완성하고, WeeklyEvent 모델을 Shared 폴더로 이동하여 확장한다.

## 2. Affected Files

### New Files (생성)
- `Woontech/Shared/Models/WeeklyEvent.swift` — WeeklyEvent 모델, 열거형 EventType/Impact/TimeGroup 포함
- `Woontech/Features/Home/WeeklyEventsSection.swift` — Section 7: 이번 주 흐름 (header + timeGroup divider + event cards)
- `Woontech/Features/Home/Views/EventCardView.swift` — Event card UI (icon, title, badge, D-day, oneLiner, investContext)
- `Woontech/Features/Home/ShareHookCard.swift` — Section 8: 공유 훅 (💌 icon + buttons)
- `Woontech/Features/Home/ProTeaserCard.swift` — Section 9: PRO 티저 (lock icon + feature list + button)
- `Woontech/Features/Home/DisclaimerView.swift` — Disclaimer (WF2 공용 면책 문구, 재사용 가능)

### Modified Files (수정)
- `Woontech/Features/Home/HomeDashboardView.swift` — ScrollView VStack 확장 (Weekly, Share, PRO, Disclaimer 추가)
- `Woontech/Features/Home/HomeRoute.swift` — WeeklyEvent 참조 경로 조정
- `Woontech/Features/Home/Providers/WeeklyEventsProviding.swift` — 프로토콜에 메서드 추가 + MockWeeklyEventsProvider 구현
- `Woontech/Features/Home/HomeDependencies.swift` — 필요시 콜백 클로저 추가 (onCalendarTap 등)
- `WoontechTests/Home/HomeDashboardTests.swift` — 유닛 테스트 케이스 추가
- `WoontechUITests/Home/HomeDashboardUITests.swift` — UI 테스트 케이스 추가 (AC-1~13)

## 3. Data Model / State Changes

### WeeklyEvent 구조 (확장된 모델)

**기본 필드:**
```
id: UUID                    // 고유 식별자
type: EventType            // enum: daewoon, jeolgi, hapchung, special
icon: String               // 이모지 (예: "🔄", "🌿", "⚠", "⭐")
title: String              // 제목 (bold)
hanja: String?             // 선택 사항 한자 (예: "大運")
dday: Int                  // D-day 숫자 (예: -89 → UI에서 "D-89")
ddayDate: String           // 포맷 날짜 (예: "4/27 월" 또는 "2026.05.12")
impact: Impact             // enum: positive, neutral, negative
oneLiner: String           // 한 줄 설명
investContext: String      // 투자 관점 텍스트
badge: String?             // 선택 사항 "중요" (positive && badge != nil일 때만 표시)
timeGroup: TimeGroup       // enum: thisWeek, thisMonth, within3Months
```

**열거형:**
```
enum EventType: String, Codable {
    case daewoon    // 대운
    case jeolgi     // 절기
    case hapchung   // 합충
    case special    // 특별
}

enum Impact: String, Codable {
    case positive   // 긍정 (일반 테두리, 선택 "중요" 배지)
    case neutral    // 중립 (일반 테두리)
    case negative   // 부정 (빨간 테두리, 좌측 accent bar, 빨간 D-day 배지)
}

enum TimeGroup: String, Codable {
    case thisWeek = "이번 주"
    case thisMonth = "이번 달"
    case within3Months = "3개월 이내"
}
```

### WeeklyEventsProviding 프로토콜 (확장)

**메서드 서명:**
```swift
protocol WeeklyEventsProviding {
    func events() -> [WeeklyEvent]
    func proFeatures() -> [String]  // Section 9용, 기본 3개
}
```

**MockWeeklyEventsProvider (와이어프레임 V6_EVENTS 기준):**
- Event 0: daewoon "대운 전환" (positive, 3개월 이내, badge="중요")
- Event 1: jeolgi "곡우" (neutral, 이번 주)
- Event 2: hapchung "월지충" (negative, 이번 주)
- Event 3: special "경신일 귀환" (neutral, 이번 달)

### HomeDashboardView 상태 변경
- `@State` 추가: 콜백 탭 카운터 (onCalendarTap, onSharePreviewTap, onShareTap, onProTrialTap) — UI 테스트용 spy

## 4. Implementation Steps (순서대로 진행)

### Step 1: WeeklyEvent 모델 생성
**파일:** `Woontech/Shared/Models/WeeklyEvent.swift`
- `WeeklyEvent` struct, Codable + Hashable + Identifiable 준수
- 모든 필드 정의
- EventType, Impact, TimeGroup 열거형 정의
- 기본 init 제공 (와이어프레임 mock 데이터 기반)

**테스트 포인트:** 
- 모델 초기화 가능
- Hashable (같은 id = 동일 event)

### Step 2: HomeRoute 업데이트
**파일:** `Woontech/Features/Home/HomeRoute.swift`
- WeeklyEvent 참조 경로 조정 (Shared/Models에서 import)
- 기존 코드 호환성 유지

### Step 3: WeeklyEventsProviding 프로토콜 및 Mock 구현
**파일:** `Woontech/Features/Home/Providers/WeeklyEventsProviding.swift`
- 프로토콜: `func events() -> [WeeklyEvent]`, `func proFeatures() -> [String]` 추가
- MockWeeklyEventsProvider: 4개 이벤트 반환 (와이어프레임 기준)
- proFeatures(): ["6개월 흐름 리포트", "성향 vs 실제 행동 주간 리포트", "AI 사주 상담사"]

**테스트 포인트:**
- Mock 반환 이벤트 수 = 4
- 각 이벤트 type/timeGroup/impact 정확성

### Step 4: DisclaimerView 생성
**파일:** `Woontech/Features/Home/DisclaimerView.swift`
- WF2 공용 면책 문구 텍스트 (이미 존재하면 참조)
- 텍스트: "본 앱은 학습·참고용이며 투자 권유가 아닙니다…"
- 재사용 가능한 view (WF3-02 이후 모든 화면에서 사용)
- 하단 padding 고정값

### Step 5: EventCardView 생성
**파일:** `Woontech/Features/Home/Views/EventCardView.swift`
- Single event card UI
- 좌측: icon (이모지)
- 중앙: title (bold) + 선택 "중요" 배지 (impact=positive && badge != nil)
- 좌측 아래: oneLiner (회색 텍스트)
- 우측 상단: D-day 배지 (예: "D-4", 색상=red if negative else muted)
- 중앙 아래: 날짜 텍스트 (예: "4/27 월")
- 하단: 회색 박스 안에 💹 + investContext + "알림 ›"

**조건부 스타일:**
- impact=negative: 빨간 테두리 + 좌측 3pt 빨간 accent bar + D-day 배지 색 = red
- impact=positive or neutral: 일반 테두리

**탭 액션:**
- Card 전체 탭 → `HomeRoute.event(event)` push

**테스트 포인트:**
- negative 이벤트: 빨간 border + accent bar + D-day 배지 색
- positive + badge: "중요" 표시
- Card tap → route append

### Step 6: WeeklyEventsSection 생성
**파일:** `Woontech/Features/Home/WeeklyEventsSection.swift`
- Section header: "이번 주 흐름" + 서브타이틀 "다가올 절기·대운 이벤트" + "캘린더 보기 ›"
- timeGroup 순서 고정: ["이번 주", "이번 달", "3개월 이내"]
- 각 timeGroup에 대해:
  - 이벤트 필터링 (timeGroup 매칭)
  - 이벤트 없으면 → 그룹 전체 숨김 (divider + cards)
  - 이벤트 있으면 → divider + card list 렌더
- Divider 스타일: 텍스트 + 우측 회색 라인
- Card gap = 6pt

**탭 액션:**
- "캘린더 보기 ›" → `onCalendarTap()` 콜백 호출
- Event card → EventCardView 탭 액션 (route push)

**테스트 포인트:**
- Empty timeGroup → divider 숨김
- 올바른 timeGroup 순서
- 섹션 헤더 항상 표시 (또는 스펙 재확인)

### Step 7: ShareHookCard 생성
**파일:** `Woontech/Features/Home/ShareHookCard.swift`
- 회색 배경 카드 (gray 색상)
- 상단: 💌 icon + 제목 "내 사주 카드로 친구 초대" + 설명 "둘 다 PRO 1개월 무료"
- 하단 버튼 2개 (flex layout, gap 6pt):
  - "카드 미리보기" → `onSharePreviewTap()` 호출
  - "공유하기" (primary) → `onShareTap()` 호출

**탭 액션:**
- 각 버튼 탭 → 해당 콜백 호출

**테스트 포인트:**
- 두 버튼 모두 존재
- 각 버튼 탭 카운트 1회 증가

### Step 8: ProTeaserCard 생성
**파일:** `Woontech/Features/Home/ProTeaserCard.swift`
- 카드 내부:
  - 상단: lock icon + 제목 "PRO로 더 깊은 분석"
  - 중단: feature bullet list (provider로부터 받음)
    - 각 bullet: 동심원 icon + 텍스트
    - 기본 3개, 배열 길이 0이면 bullet 영역 숨김
  - 하단: "7일 무료 체험 →" 버튼 (primary)

**탭 액션:**
- "7일 무료 체험 →" → `onProTrialTap()` 호출

**테스트 포인트:**
- Bullet 개수 = provider 배열 길이
- Empty array → bullet 영역 숨김
- Button tap → 카운트 1회 증가

### Step 9: HomeDashboardView ScrollView 확장
**파일:** `Woontech/Features/Home/HomeDashboardView.swift`
- 기존 구조 유지 (header + NavigationStack)
- ScrollView VStack 내부 순서:
  1. HeroInvestingCardView
  2. InsightsScrollView
  3. WeeklyEventsSection (제공자: homeDeps.weeklyEvents)
  4. ShareHookCard
  5. ProTeaserCard
  6. DisclaimerView
- 하단 padding = 49 (tabBar) + 16pt
- accessibilityIdentifier 유지: "HomeDashboardContent"

**콜백 연결:**
- WeeklyEventsSection.onCalendarTap → 상태 업데이트 (카운터 증가 또는 나중에 route append)
- ShareHookCard.onSharePreviewTap → 카운터 증가
- ShareHookCard.onShareTap → 카운터 증가
- ProTeaserCard.onProTrialTap → 카운터 증가

**Spy counters:**
```swift
@State private var calendarTapCount = 0
@State private var sharePreviewTapCount = 0
@State private var shareTapCount = 0
@State private var proTrialTapCount = 0
```

**테스트용 overlay (기존 패턴 따름):**
- 각 카운터를 opacity=0 Text로 노출 (accessibility identifier)

### Step 10: 콜백 매개변수 추가 (필요시)
**선택 사항:** HomeDependencies 또는 HomeDashboardView에 콜백 클로저 추가
- onCalendarTap: () -> Void
- onSharePreviewTap: () -> Void
- onShareTap: () -> Void
- onProTrialTap: () -> Void

스펙에서는 "placeholder action"이므로 일단 상태 카운터로 처리, 나중에 실제 네비게이션으로 전환 가능.

### Step 11: 유닛 테스트 작성
**파일:** `WoontechTests/Home/HomeDashboardTests.swift`
- 아래 단계 5에서 상세 기술

### Step 12: UI 테스트 작성
**파일:** `WoontechUITests/Home/HomeDashboardUITests.swift`
- 아래 단계 6에서 상세 기술

## 5. Unit Test Plan

### Test Category 1: WeeklyEvent 모델
```
test_weeklyEvent_initialization_default
  → WeeklyEvent()가 기본값으로 생성되는가?

test_weeklyEvent_hashable_sameID_equal
  → 같은 id를 가진 두 event가 equal?

test_weeklyEvent_identifiable_hasID
  → id 프로퍼티가 Identifiable 준수하는가?
```

### Test Category 2: EventType/Impact/TimeGroup 열거형
```
test_eventType_allCases_decodable
  → 모든 case가 String rawValue로 인코딩/디코딩 가능?

test_impact_negativeCase_identified
  → negative case 식별 가능?

test_timeGroup_thisWeek_stringValue
  → timeGroup.thisWeek의 string 값 = "이번 주"?
```

### Test Category 3: MockWeeklyEventsProvider
```
test_mockWeeklyEventsProvider_returns4Events
  → events() 반환 배열 길이 = 4?

test_mockWeeklyEventsProvider_event0_isDaewoon
  → events()[0].type == .daewoon && title == "대운 전환"?

test_mockWeeklyEventsProvider_event1_isThisWeek
  → events()[1].timeGroup == .thisWeek?

test_mockWeeklyEventsProvider_event2_isNegativeImpact
  → events()[2].impact == .negative?

test_mockWeeklyEventsProvider_event3_isThisMonth
  → events()[3].timeGroup == .thisMonth?

test_mockWeeklyEventsProvider_proFeatures_returns3
  → proFeatures() 길이 = 3?

test_mockWeeklyEventsProvider_proFeatures_correctText
  → proFeatures()[0] == "6개월 흐름 리포트"?
```

### Test Category 4: Event 필터링 로직
```
test_eventFilter_byTimeGroup_thisWeek
  → 모든 이벤트에서 thisWeek만 필터? 
  → 예상: [event1, event2] (개수 2)

test_eventFilter_byTimeGroup_thisMonth
  → thisMonth만 필터?
  → 예상: [event3] (개수 1)

test_eventFilter_byTimeGroup_within3Months
  → within3Months만 필터?
  → 예상: [event0] (개수 1)

test_eventFilter_empty_returnsNone
  → 빈 배열 필터?
  → 예상: [] (개수 0)
```

### Test Category 5: Impact 스타일 로직
```
test_negativeImpact_borderColor_isRed
  → impact == .negative → border color = red?

test_negativeImpact_accentBar_visible
  → impact == .negative → left accent bar width = 3pt?

test_negativeImpact_ddayBadge_colorRed
  → impact == .negative → dday badge color = red?

test_positiveImpactWithBadge_badgeShown
  → impact == .positive && badge == "중요" → badge visible?

test_positiveImpactWithoutBadge_badgeHidden
  → impact == .positive && badge == nil → badge hidden?

test_neutralImpact_noRedStyling
  → impact == .neutral → border color = normal (not red)?
```

### Test Category 6: HomeRoute
```
test_homeRoute_eventCase_hashable
  → HomeRoute.event(event)가 Hashable?

test_homeRoute_event_sameIDequality
  → 같은 event id → 같은 route?

test_homeRoute_allCases_inSet
  → Set<HomeRoute> 저장 가능?
```

## 6. UI Test Plan (Acceptance Criteria별)

### AC-1: ScrollView 단일 스크롤
```
test_homeDashboard_singleScrollView_allSectionsReachable
  → ScrollView 내 모든 섹션 스크롤 접근 가능?
  
  Steps:
  1. App 런치 with "-openHome"
  2. HomeDashboardContent (ScrollView) 찾음
  3. 아래로 스크롤 → HeroInvestingCardView 보임
  4. 계속 스크롤 → WeeklyEventsSection 보임
  5. 계속 스크롤 → ShareHookCard 보임
  6. 계속 스크롤 → ProTeaserCard 보임
  7. 계속 스크롤 → DisclaimerView 텍스트 보임
  8. 최하단 도달 시 TabBar 위 높이 확인
```

### AC-2: timeGroup 순서 정렬
```
test_weeklyEventsSection_timeGroupOrder_correct
  → 이벤트가 "이번 주" → "이번 달" → "3개월 이내" 순서?
  
  Steps:
  1. App 런치
  2. WeeklyEventsSection 렌더 대기
  3. "이번 주" divider 찾음 (index 0)
  4. "이번 달" divider 찾음 (index 1)
  5. "3개월 이내" divider 찾음 (index 2)
  6. 순서 확인
```

### AC-3: 빈 timeGroup 숨김
```
test_weeklyEventsSection_emptyTimeGroup_hidden
  → "이번 달" 이벤트만 있으면 다른 그룹 숨김?
  
  Steps:
  1. MockWeeklyEventsProvider를 override (이번 달 이벤트만)
  2. App 런치
  3. "이번 주" divider 존재하지 않음 확인
  4. "3개월 이내" divider 존재하지 않음 확인
  5. "이번 달" divider만 존재 확인
  6. 해당 그룹의 카드 렌더됨 확인
```

### AC-4: Negative impact 스타일
```
test_eventCard_negativeImpact_hasRedStyling
  → negative 이벤트 카드 = 빨간 테두리 + accent bar + 빨간 D-day?
  
  Steps:
  1. App 런치
  2. "월지충" 카드 찾음 (impact=negative)
  3. 카드 프레임 검사:
     - 좌측 3pt 빨간 accent bar 확인
     - 테두리 색 = red 확인
     - D-day 배지 텍스트 색 = red 확인
```

### AC-5: "중요" 배지 조건
```
test_eventCard_importantBadge_logic
  → positive && badge="중요"만 표시?
  
  Steps:
  1. "대운 전환" 카드 (positive, badge="중요") 찾음
  2. "중요" 배지 보임 확인
  3. "곡우" 카드 (neutral) 찾음
  4. "중요" 배지 보이지 않음 확인
  5. "월지충" 카드 (negative) 찾음
  6. "중요" 배지 보이지 않음 확인
```

### AC-6: 이벤트 카드 탭 → 라우트
```
test_eventCard_tap_pushesEventRoute
  → 카드 탭 → HomeRoute.event(event) append?
  
  Steps:
  1. App 런치
  2. 첫 번째 이벤트 카드 탭 (대운 전환)
  3. EventPlaceholderView 나타남 확인 (HomeRoute_eventDest)
  4. 뒤로 가기
  5. 다른 카드 탭 (곡우)
  6. 역시 EventPlaceholderView 나타남 확인
  
  Spy: event.id 일치 검증 (스파이로 navigationPath append 감시)
```

### AC-7: 공유 카드 버튼
```
test_shareHookCard_buttons_callCallbacks
  → "카드 미리보기" & "공유하기" 각 1회 호출?
  
  Steps:
  1. App 런치
  2. "카드 미리보기" 버튼 탭
  3. sharePreviewTapCount == 1 확인 (spy)
  4. "공유하기" 버튼 탭
  5. shareTapCount == 1 확인 (spy)
```

### AC-8: PRO 기능 리스트
```
test_proTeaserCard_features_matchProvider
  → 기능 bullet 개수 = provider 배열 길이?
  
  Steps:
  1. 기본 mock (3개 기능):
     - App 런차
     - 3개 bullet 모두 보임 확인
     - 텍스트: "6개월 흐름 리포트", "성향 vs 실제 행동 주간 리포트", "AI 사주 상담사"
  
  2. 빈 배열 mock:
     - App 런치 (custom provider, proFeatures() = [])
     - bullet 영역 보이지 않음 (숨김)
```

### AC-9: PRO 버튼
```
test_proTeaserCard_trialButton_callsCallback
  → "7일 무료 체험 →" 탭 → onProTrialTap() 1회?
  
  Steps:
  1. App 런치
  2. "7일 무료 체험 →" 버튼 탭
  3. proTrialTapCount == 1 확인 (spy)
```

### AC-10: 캘린더 버튼
```
test_weeklyEventsSection_calendarButton_callsCallback
  → "캘린더 보기 ›" 탭 → onCalendarTap() 1회?
  
  Steps:
  1. App 런치
  2. WeeklyEventsSection 헤더 "캘린더 보기 ›" 탭
  3. calendarTapCount == 1 확인 (spy)
```

### AC-11: Disclaimer 최하단
```
test_disclaimer_atBottom
  → DisclaimerView가 ScrollView 최하단?
  
  Steps:
  1. App 런치
  2. ScrollView 최하단까지 스크롤
  3. DisclaimerView 텍스트 보임
  4. TabBar 위에 있음 확인 (padding = 49 + 16)
```

### AC-12: 빈 이벤트 배열
```
test_weeklyEventsSection_empty_headerVisible
  → 빈 배열 시 섹션 헤더 보임, 모든 그룹 숨김?
  
  Steps:
  1. MockWeeklyEventsProvider override (events() = [])
  2. App 런치
  3. "이번 주 흐름" 헤더 보임 (또는 숨김 — 스펙 재확인)
  4. 모든 timeGroup divider 보이지 않음
  5. 이벤트 카드 0개
  
  참고: 스펙 AC-12에서 "섹션 헤더는 보이되" vs "섹션 헤더 전체 숨김" 중 하나로 확정 필요
```

### AC-13: Dynamic Type XL
```
test_dynamicTypeXL_eventCardText_wrapping
  → XL 크기에서 investContext 텍스트 wrapping, not truncated?
  
  Steps:
  1. 환경 설정: UIContentSizeCategoryOverride = "UICTContentSizeCategoryAccessibilityL"
  2. App 런치
  3. 이벤트 카드 찾음
  4. investContext 회색 박스 내 텍스트 보임
  5. 텍스트 프레임 높이 > 예상 (wrapping 확인)
  6. truncation 없음 확인
```

## 7. Risks / Open Questions

### Risk 1: 콜백 메커니즘 미정의
**문제:** 스펙에서 `onCalendarTap`, `onSharePreviewTap`, `onShareTap`, `onProTrialTap`을 언급하지만 정확한 정의/전달 방식 명시 안 됨.

**현재 가정:** HomeDashboardView 내 @State 카운터로 구현, 나중에 실제 route/네비게이션으로 전환.

**해결 방안:** 
- 구현 전 PM/design과 콜백 flow 확인
- 필요시 HomeDependencies에 클로저 추가

### Risk 2: WeeklyEventsProviding 메서드 시그니처
**문제:** 프로토콜 메서드 명칭/시그니처 스펙에 없음.

**현재 가정:**
```swift
func events() -> [WeeklyEvent]
func proFeatures() -> [String]
```

**해결 방안:** 스펙 재검토 또는 설계자 확인 필요.

### Risk 3: Disclaimer 텍스트 소스
**문제:** WF2 공용 면책 문구 정확한 텍스트 스펙에 없음.

**현재 가정:** "본 앱은 학습·참고용이며 투자 권유가 아닙니다…" (일반적인 한국 투자 앱 disclaimer).

**해결 방안:** 기존 WF2 코드에서 텍스트 찾거나, PM에 정확한 문구 요청.

### Risk 4: TimeGroup enum vs String
**문제:** 스펙에서 문자열 "이번 주", "이번 달", "3개월 이내" 사용. Model은 enum으로 타입-세이프하게 하되, UI 표시 시 로컬라이징 필요.

**현재 가정:** TimeGroup enum with rawValue = Korean string.

**해결 방안:** 
```swift
enum TimeGroup: String, Codable {
    case thisWeek = "이번 주"
    case thisMonth = "이번 달"
    case within3Months = "3개월 이내"
}
```

### Risk 5: D-day 표현 (정수 vs 문자열)
**문제:** 데이터는 `dday: Int` (-89 등)이지만 UI 표시는 "D-89" 형식. 변환 로직 필요.

**현재 가정:** EventCardView에서 `"D-\(abs(dday))"` 포맷.

**해결 방안:** Helper 함수 또는 computed property로 변환.

### Risk 6: 섹션 헤더 visibility (AC-12)
**문제:** 이벤트 배열이 비어있을 때, "이번 주 흐름" 섹션 헤더를 표시할지 말지 불명확.

**스펙:** "섹션 헤더는 보이되 모든 그룹 divider/카드가 숨겨진다" vs "섹션 헤더 전체 숨김"

**해결 방안:** 구현 중 선택 후 테스트 반영. 추천: 섹션 헤더 보임 (UX: 콘텐츠 로딩 신호).

### Risk 7: Dynamic Type 테스트 범위
**문제:** 스펙에서 "Dynamic Type Large"와 AC-13 "XL" 혼용. 정확한 범위 미정의.

**현재 가정:** 기본(Large) + XL(Accessibility L) 두 가지 테스트.

**해결 방안:** QA와 test plan 재확인.

### Risk 8: EventCardView 상호작용 (navigationPath 직접 append)
**문제:** Event card tap 시 navigationPath에 HomeRoute.event(event)를 append해야 하는데, View 계층에서 정확한 전달 방식 필요.

**현재 가정:** EventCardView에 `onTap: (WeeklyEvent) -> Void` 클로저 전달.

**해결 방안:** 구현 시 Navigation 구조 재검토. 예시:
```swift
EventCardView(event: event) {
    navigationPath.append(.event(event))
}
```

### Risk 9: 실제 데이터 연동 시기
**문제:** 현재는 mock data. 실제 API/DB 연동은 WF3-04 이후.

**해결 방안:** 프로토콜-기반 구조 유지, 나중에 실제 provider로 교체.

### Risk 10: 성능 (long list of events)
**문제:** 이벤트 개수 증가 시 ScrollView 성능.

**해결 방안:** 현재 mock (4개)로는 문제 없음. 추후 LazyVStack 고려.

---

## 참고: 와이어프레임 참조 데이터 (V6_EVENTS)

```
Event 0: 대운 전환 (daewoon, positive, 3개월 이내, badge="중요")
Event 1: 곡우 (jeolgi, neutral, 이번 주)
Event 2: 월지충 (hapchung, negative, 이번 주)
Event 3: 경신일 귀환 (special, neutral, 이번 달)

PRO Features: ["6개월 흐름 리포트", "성향 vs 실제 행동 주간 리포트", "AI 사주 상담사"]
```

---

**작성일:** 2026-04-25  
**작성자:** Claude Code Planner  
**버전:** v1
