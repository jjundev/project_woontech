# Implementation Checklist — WF4-06 사주 공부 리스트

## Requirements (from spec)

- [ ] R1 (AC1): `SajuLearnListView`가 WF4-03의 "전체 ›" 버튼 또는 학습 경로 카드 탭 시 NavigationStack push된다.
- [ ] R2 (AC2): NavBar 타이틀 "사주 공부" + trailing muted "검색" 텍스트(탭 no-op, accessibility hint "준비중").
- [ ] R3 (AC3): 카테고리 pill 영역은 항상 `[전체, 입문, 오행, 십성, 대운, 합충]` 고정 순서로 6개 렌더된다.
- [ ] R4 (AC4): 첫 진입 시 "전체" pill만 선택 상태(검정 배경 + 흰 글씨 bold), 나머지 pill은 흰 배경 + 회색 테두리.
- [ ] R5 (AC5): 임의의 pill 탭 시 해당 pill만 선택 상태로 전환(단일 선택); 코스 리스트 내용은 변화하지 않는다.
- [ ] R6 (AC6): 주간 배너의 streak 배지는 `streakDays > 0`일 때만 노출, 0이면 숨김. "{completed} / {total}강 완료" 텍스트가 정확히 바인딩된다.
- [ ] R7 (AC7): 진행률 바 너비 = `clamp(ratio, 0, 1) × 100%`. Mock 기본값(0.6) → 60%.
- [ ] R8 (AC8): 코스 헤더에 `"{course.name} 코스"` + `"{lessonCount}강 · 평균 {averageMinutes}분"` 이 정확히 바인딩된다.
- [ ] R9 (AC9): 코스 리스트는 `course.lessons` 배열 순서대로 렌더, 카드 수 = `lessonCount` (mock 기본값 7개).
- [ ] R10 (AC10): completed 카드 인디케이터 = 검정 배경 + 흰 체크 SVG.
- [ ] R11 (AC11): current 카드 인디케이터 = 흰 배경 + 검정 굵은 테두리 + 번호 텍스트; 메타 라인에 ` · 이어보기` 추가; 타이틀 더 진한 bold.
- [ ] R12 (AC12): pending 카드 인디케이터 = 회색 테두리 + 번호 텍스트(검정); 우측 `›` chevron.
- [ ] R13 (AC13): locked 카드 인디케이터 = 회색 테두리 + 번호(muted); 우측 자물쇠 SVG.
- [ ] R14 (AC14): completed/current/pending 카드 탭 시 `SajuRoute.lesson(id: row.id)`가 NavigationStack path에 push된다.
- [ ] R15 (AC15): locked 카드 탭 시 path 변화 없음; 하단 "이전 강의를 먼저 완료하세요" 토스트 표시(2초 자동 닫힘); VoiceOver announcement로 동일 문구 읽힘.
- [ ] R16 (AC16): 추천 아티클 섹션은 `recommendedArticles.count` 개 카드 렌더; 빈 배열이면 헤더 포함 섹션 전체 숨김.
- [ ] R17 (AC17): 추천 아티클 카드 탭은 no-op; VoiceOver hint "준비중".
- [ ] R18 (AC18): NavBar "검색" 탭은 no-op; accessibility hint "준비중".
- [ ] R19 (AC19): 인터랙티브 요소(pill 6개, 레슨 카드 N개, 추천 카드, NavBar 검색)의 hit target ≥ 44×44pt.
- [ ] R20 (AC20): Dynamic Type XL에서 카드 타이틀/메타 wrapping 정상, 인디케이터 원 28pt 유지.

---

## Implementation Steps

- [ ] S1 (Step 1): `SajuLearningPathProviding.swift` 모델 타입 추가
  - [ ] S1-a: `WeeklyProgress`에 `ratio` computed property 추가 (`goal > 0 ? Double(completed)/Double(goal) : 0.0`)
  - [ ] S1-b: `LessonStatus`, `LessonRow`, `CourseSection`, `LearnCategory`, `Article` 타입 추가
  - [ ] S1-c: `SajuLearningPathProviding` 프로토콜에 `learnCategories`, `introductoryCourse`, `recommendedArticles` 요건 추가
  - [ ] S1-d: Protocol extension에 default 구현 3개 추가 (기존 채택자 컴파일 보호)
  - [ ] S1-e: `MockSajuLearningPathProvider` 기본값 확장 (categories 6개, 7-레슨 입문 코스, 아티클 2건, spec 그대로)

- [ ] S2 (Step 2): `SajuLessonRowCardView.swift` 신규 생성
  - [ ] S2-a: 4-상태 인디케이터(28×28pt) 구현 (completed/current/pending/locked 각 스타일)
  - [ ] S2-b: 가운데 영역(타이틀 12pt bold, 메타 9pt muted; current이면 ` · 이어보기` 추가)
  - [ ] S2-c: 우측 아이콘(locked → lock.fill muted, 그 외 → chevron.right muted)
  - [ ] S2-d: `onTap` 콜백 연결, hit target `.frame(minHeight: 44).contentShape(Rectangle())`
  - [ ] S2-e: accessibility label 구성 + locked `.accessibilityAddTraits(.notEnabled)`
  - [ ] S2-f: `static func statusKorean(_ status: LessonStatus) -> String` helper 노출

- [ ] S3 (Step 3): `SajuLearnCategoryPillsView.swift` 신규 생성
  - [ ] S3-a: `ScrollView(.horizontal, showsIndicators: false)` + `HStack(spacing: 6)`
  - [ ] S3-b: 내부 HStack에 `.padding(.leading, 16).padding(.trailing, 16)` 적용 (부모에서 별도 horizontal padding 없음)
  - [ ] S3-c: 선택 pill: `Capsule().fill(.black)` + white bold text; 미선택: stroke + ink text
  - [ ] S3-d: 탭 시 `selectedId.wrappedValue = category.id`
  - [ ] S3-e: accessibility label `"\(label), \(isSelected ? "선택됨" : "선택 안됨")"`

- [ ] S4 (Step 4): `SajuWeeklyProgressBannerView.swift` 신규 생성
  - [ ] S4-a: RoundedRectangle 카드(cornerRadius 10pt, stroke line3), 내부 padding 12pt
  - [ ] S4-b: 좌측 — "이번 주 학습" muted 9pt + `streakDays > 0` 조건부 streak 배지 + "{completed} / {goal}강 완료" bold 14pt
  - [ ] S4-c: 우측 — 44×44pt placeholder RoundedRectangle
  - [ ] S4-d: 하단 진행률 바 (높이 4pt, GeometryReader로 `clamp(ratio, 0, 1)` × 전체 너비)
  - [ ] S4-e: `.accessibilityElement(children: .ignore)` + label 구성
  - [ ] S4-f: `static func clampedRatio(_ raw: Double) -> Double` helper 노출

- [ ] S5 (Step 5): `SajuLearnArticleCardView.swift` 신규 생성
  - [ ] S5-a: 좌측 44×44pt placeholder + 우측 title bold 11pt + meta muted 9pt
  - [ ] S5-b: 탭은 `onTap` 콜백 (상위에서 no-op 제공)
  - [ ] S5-c: `.accessibilityHint("준비중")`, `.frame(minHeight: 44)`

- [ ] S6 (Step 6): `SajuLearnListView.swift` 신규 생성
  - [ ] S6-a: `@State private var selectedCategoryId: String = "all"`, `toastVisible`, `toastTask`
  - [ ] S6-b: NavBar — `.navigationTitle("사주 공부")`, `.navigationBarTitleDisplayMode(.inline)`, trailing "검색" Text with `.accessibilityHint("준비중")`
  - [ ] S6-c: Body — `ZStack(alignment: .bottom)` 최외곽; `ScrollView` 안 outer `VStack`
  - [ ] S6-d: Pill strip (`SajuLearnCategoryPillsView`) — outer VStack의 최상단, horizontal padding 없음
  - [ ] S6-e: 나머지 콘텐츠(배너, 코스 헤더, 레슨 리스트, 아티클 섹션)는 `.padding(.horizontal, 16)` 적용 내부 VStack에 배치
  - [ ] S6-f: `handleLessonTap()` — completed/current/pending → `onNavigate(.lesson(id:))`; locked → `showLockedToast()`
  - [ ] S6-g: `showLockedToast()` — `toastTask?.cancel()`, `withAnimation { toastVisible = true }`, `UIAccessibility.post(.announcement, ...)`, `Task { sleep 2s → toastVisible = false }`
  - [ ] S6-h: Toast overlay (`ToastBannerView`) — safe area 위, `.transition(.opacity.combined(with: .move(edge: .bottom)))`, `.animation(.easeInOut, value: toastVisible)`
  - [ ] S6-i: `CourseHeaderView` (inner) — 좌측 bold 12pt "{name} 코스", 우측 muted 10pt "{lessonCount}강 · 평균 {averageMinutes}분"
  - [ ] S6-j: Accessibility identifier 정책 전체 적용 (`SajuLearnListView`, `SajuLearnCategoryPill_\(id)`, `SajuLearnWeeklyBanner`, `SajuLearnStreakBadge`, `SajuLearnCourseHeader`, `SajuLearnLessonCard_\(id)`, `SajuLearnArticleSection`, `SajuLearnArticleCard_\(id)`, `SajuLearnToast`)

- [ ] S7 (Step 7): `SajuRouteDestinations.swift` — `.learn` case를 `SajuLearnListView(provider:onNavigate:)`로 교체

- [ ] S8 (Step 8): `WoontechApp.swift` — `-sajuLearnArticlesEmpty` 및 `-sajuLearnStreakZero` launch arg 파싱 추가, MockSajuLearningPathProvider 조건부 초기화

- [ ] S9 (Step 9): `SajuTabFoundationUITests.swift` T20 — assertion을 `SajuLearnListView` identifier로 교체

- [ ] S10 (Step 10): `SajuLearnListTests.swift` 단위 테스트 작성 (TL-01 ~ TL-30, §5 참고)

- [ ] S11 (Step 11): `SajuLearnListUITests.swift` UI 테스트 작성 (TU-L01 ~ TU-L31, §6 참고)

---

## Tests

### Unit Tests (`WoontechTests/Saju/SajuLearnListTests.swift`)

- [ ] T1 (TL-01, unit): `test_mockProvider_learnCategories_count_is6` — `learnCategories.count == 6` [AC3]
- [ ] T2 (TL-02, unit): `test_mockProvider_learnCategories_order_fixed` — 순서 `[전체,입문,오행,십성,대운,합충]` [AC3]
- [ ] T3 (TL-03, unit): `test_learnListView_initialSelectedCategoryId_isAll` — 초기 `selectedCategoryId == "all"` [AC4]
- [ ] T4 (TL-04, unit): `test_pill_selection_switchHighlights` — selectedId 바인딩 변경 시 이전 pill 미선택 [AC5]
- [ ] T5 (TL-05, unit): `test_weeklyProgress_ratio_completedDivGoal` — `WeeklyProgress(completed:3,goal:5).ratio ≈ 0.6` [AC7]
- [ ] T6 (TL-06, unit): `test_weeklyProgress_ratio_clamp_above1` — `clampedRatio(1.2) == 1.0` [AC7]
- [ ] T7 (TL-07, unit): `test_weeklyProgress_ratio_clamp_below0` — `clampedRatio(-0.1) == 0.0` [AC7]
- [ ] T8 (TL-08, unit): `test_weeklyProgress_ratio_goalZero_returns0` — `WeeklyProgress(completed:0,goal:0).ratio == 0.0` [AC7]
- [ ] T9 (TL-09, unit): `test_weeklyBanner_streakBadge_hidden_when0` — `streakDays == 0 → badge 조건 false` [AC6]
- [ ] T10 (TL-10, unit): `test_weeklyBanner_streakBadge_shown_when3` — `streakDays == 3 → badge 조건 true` [AC6]
- [ ] T11 (TL-11, unit): `test_weeklyBanner_text_completed_total_binding` — `"3 / 5강 완료"` (mock 기본값) [AC6]
- [ ] T12 (TL-12, unit): `test_courseHeader_name_binding` — `"입문 코스"` [AC8]
- [ ] T13 (TL-13, unit): `test_courseHeader_lessonCount_averageMinutes` — `"7강 · 평균 3분"` [AC8]
- [ ] T14 (TL-14, unit): `test_courseList_count_matches_lessonCount` — `lessons.count == lessonCount == 7` [AC9]
- [ ] T15 (TL-15, unit): `test_lessonRow_statusKorean_completed` — `statusKorean(.completed) == "완료"` [AC10]
- [ ] T16 (TL-16, unit): `test_lessonRow_statusKorean_current` — `statusKorean(.current) == "현재"` [AC11]
- [ ] T17 (TL-17, unit): `test_lessonRow_statusKorean_pending` — `statusKorean(.pending) == "미완료"` [AC12]
- [ ] T18 (TL-18, unit): `test_lessonRow_statusKorean_locked` — `statusKorean(.locked) == "잠김"` [AC13]
- [ ] T19 (TL-19, unit): `test_lessonRow_current_meta_includes_이어보기` — current 메타에 ` · 이어보기` 포함 [AC11]
- [ ] T20 (TL-20, unit): `test_lessonRow_pending_meta_no_이어보기` — pending 메타에 ` · 이어보기` 미포함 [AC12]
- [ ] T21 (TL-21, unit): `test_handleLessonTap_completed_firesRoute` — `onNavigate(.lesson(id:))` 호출됨 [AC14]
- [ ] T22 (TL-22, unit): `test_handleLessonTap_current_firesRoute` — `onNavigate(.lesson(id:))` 호출됨 [AC14]
- [ ] T23 (TL-23, unit): `test_handleLessonTap_pending_firesRoute` — `onNavigate(.lesson(id:))` 호출됨 [AC14]
- [ ] T24 (TL-24, unit): `test_handleLessonTap_locked_doesNotFireRoute` — locked 탭 → `onNavigate` 미호출 [AC15]
- [ ] T25 (TL-25, unit): `test_recommendedArticles_sectionHidden_whenEmpty` — 빈 배열 → 섹션 숨김 조건 true [AC16]
- [ ] T26 (TL-26, unit): `test_recommendedArticles_count_matches_provider` — mock 2건 → 카드 2개 [AC16]
- [ ] T27 (TL-27, unit): `test_articleCard_tap_noRouteChange` — 아티클 탭 → navigate 미호출 [AC17]
- [ ] T28 (TL-28, unit): `test_mockProvider_introductoryCourse_lesson4_isCurrent` — `lessons[3].status == .current` [AC11]
- [ ] T29 (TL-29, unit): `test_mockProvider_introductoryCourse_lesson5_isLocked` — `lessons[4].status == .locked` [AC13]
- [ ] T30 (TL-30, unit): `test_weeklyProgressBannerView_clampedRatio_0_6` — `clampedRatio(0.6) ≈ 0.6` [AC7]

### UI Tests (`WoontechUITests/Saju/SajuLearnListUITests.swift`)

- [ ] T31 (TU-L01, ui): `test_navigate_fromBelowFold_allButton` — "전체 ›" 탭 → `SajuLearnListView` push [AC1]
- [ ] T32 (TU-L02, ui): `test_navigate_fromBelowFold_courseCard` — `SajuCourseCard_입문` 탭 → `SajuLearnListView` push [AC1]
- [ ] T33 (TU-L03, ui): `test_navBar_title_사주공부` — navigationTitle == "사주 공부" [AC2]
- [ ] T34 (TU-L04, ui): `test_navBar_searchButton_exists` — `SajuLearnSearchButton` exists [AC2]
- [ ] T35 (TU-L05, ui): `test_navBar_searchButton_tap_isNoOp` — 탭 후 `SajuLearnListView` still exists [AC18]
- [ ] T36 (TU-L06, ui): `test_categoryPills_count_is6` — `SajuLearnCategoryPill_*` × 6 [AC3]
- [ ] T37 (TU-L07, ui): `test_categoryPills_order_fixed` — minX frame 순서 검증 (전체 < 입문 < ... < 합충) [AC3]
- [ ] T38 (TU-L08, ui): `test_categoryPills_initialSelection_전체` — `SajuLearnCategoryPill_all` label contains "선택됨" [AC4]
- [ ] T39 (TU-L09, ui): `test_categoryPills_switchSelection` — 입문 탭 후 `all` 미선택, `intro` 선택됨 [AC5]
- [ ] T40 (TU-L10, ui): `test_weeklyBanner_exists` — `SajuLearnWeeklyBanner` exists [AC6]
- [ ] T41 (TU-L11, ui): `test_weeklyBanner_streakBadge_visible_default` — `SajuLearnStreakBadge` exists + label "연속 3일" [AC6]
- [ ] T42 (TU-L12, ui): `test_weeklyBanner_streakBadge_hidden_streakDays0` — `-sajuLearnStreakZero` launch → `SajuLearnStreakBadge` not exists [AC6]
- [ ] T43 (TU-L13, ui): `test_weeklyBanner_completedTotalText` — "3 / 5강 완료" exists in staticTexts [AC6]
- [ ] T44 (TU-L14, ui): `test_courseHeader_text` — `SajuLearnCourseHeader` label contains "입문 코스" and "7강 · 평균 3분" [AC8]
- [ ] T45 (TU-L15, ui): `test_courseList_7cards_exist` — `SajuLearnLessonCard_L1` ~ `_L7` exist [AC9]
- [ ] T46 (TU-L16, ui): `test_lessonCard_completed_accessibilityLabel` — `SajuLearnLessonCard_L1` label contains "완료" [AC10]
- [ ] T47 (TU-L17, ui): `test_lessonCard_current_continueLabel` — `SajuLearnLessonCard_L4` label contains "이어보기" [AC11]
- [ ] T48 (TU-L18, ui): `test_lessonCard_locked_label` — `SajuLearnLessonCard_L5` label contains "잠김" [AC13]
- [ ] T49 (TU-L19, ui): `test_lessonCard_completed_tap_pushesLesson` — `SajuLearnLessonCard_L1` 탭 → lesson route id="L1" [AC14]
- [ ] T50 (TU-L20, ui): `test_lessonCard_current_tap_pushesLesson` — `SajuLearnLessonCard_L4` 탭 → lesson route id="L4" [AC14]
- [ ] T51 (TU-L21, ui): `test_lessonCard_locked_tap_showsToast` — `SajuLearnLessonCard_L5` 탭 → `SajuLearnToast` exists [AC15]
- [ ] T52 (TU-L22, ui): `test_lessonCard_locked_tap_pathUnchanged` — 토스트 후 `SajuLearnListView` still on screen [AC15]
- [ ] T53 (TU-L23, ui): `test_toast_autoDismiss_after2sec` — 3초 후 `SajuLearnToast` not exists [AC15]
- [ ] T54 (TU-L24, ui): `test_articleSection_visible_default` — `SajuLearnArticleSection` exists [AC16]
- [ ] T55 (TU-L25, ui): `test_articleSection_2cards` — `SajuLearnArticleCard_A1`, `_A2` exist [AC16]
- [ ] T56 (TU-L26, ui): `test_articleSection_hidden_whenEmpty` — `-sajuLearnArticlesEmpty` launch → `SajuLearnArticleSection` not exists [AC16]
- [ ] T57 (TU-L27, ui): `test_articleCard_tap_noNavigation` — `SajuLearnArticleCard_A1` 탭 → `SajuLearnListView` still exists [AC17]
- [ ] T58 (TU-L28, ui): `test_hitTarget_pills_minSize44` — 6개 pill frame.height ≥ 44 [AC19]
- [ ] T59 (TU-L29, ui): `test_hitTarget_lessonCards_minSize44` — 7개 lesson card frame.height ≥ 44 [AC19]
- [ ] T60 (TU-L30, ui): `test_hitTarget_articleCards_minSize44` — 2개 article card frame.height ≥ 44 [AC19]
- [ ] T61 (TU-L31, ui): `test_dynamicType_xl_lessonCards_noTruncation` — XL Dynamic Type + lesson 카드 height > 44 + indicator 28pt 유지 [AC20]
