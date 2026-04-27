# Implementation Checklist — WF4-03 사주 탭 Below-the-Fold

---

## Requirements (from spec)

- [ ] R1: WF4-02 above-fold 마지막 요소 직후 본 섹션이 **18pt 상단 마진**으로 렌더된다 (단일 스크롤 화면 완성) (AC1)
- [ ] R2: "사주 공부하기" 섹션 헤더 좌측에 bold 12pt 타이틀 + `🔥 연속 {n}일` pill 배지(`streakDays > 0`일 때만 표시). `streakDays = 0`이면 배지 숨김 (AC2)
- [ ] R3: 헤더 우측 "전체 ›" 탭 → `SajuRoute.learn` push (AC3)
- [ ] R4: `featuredLesson` 주입 시 "오늘의 한 가지" 카드에 title / durationLabel / levelLabel이 올바르게 바인딩됨 (AC4)
- [ ] R5: "오늘의 한 가지" 카드 탭 → `SajuRoute.lesson(id: featuredLesson.id)` push (AC5)
- [ ] R6: `featuredLesson = nil` 시 오늘의 한 가지 카드 전체 숨김 + 그리드가 헤더 바로 아래로 이동 (AC6)
- [ ] R7: 학습 경로 그리드는 `[입문, 오행, 십성, 대운]` 고정 순서로 항상 4슬롯 렌더 (provider 배열 순서 무관, 이름 매칭 정렬). 4개 미만 → 빈 슬롯은 lock 표현 (흐린 배경, 진행률 0) (AC7)
- [ ] R8: 각 학습 경로 카드 진행률 바 = `clamp(progress, 0…1) × 100%` 너비 (AC8)
- [ ] R9: 학습 경로 카드 탭 → `SajuRoute.learn` push (AC9)
- [ ] R10: 용어 사전 카드 subtitle = `glossaryTermCount > 0` → "명리학 용어 {N}개", `== 0` → "명리학 용어" (AC10)
- [ ] R11: 용어 사전 카드 탭 = no-op (path 변경 없음). VoiceOver hint "준비중" (AC11)
- [ ] R12: Disclaimer가 섹션 가장 아래에 렌더되며 "본 앱은 학습·참고용이며 투자 권유가 아닙니다." 문구 포함 (AC12)
- [ ] R13: 공통 TabBar가 active=2 상태로 화면 하단에 가시적 (AC13)
- [ ] R14: Dynamic Type XL에서 4-그리드 카드 타이틀/서브 wrapping OK, 진행률 바 미소실/미가려짐 (AC14)
- [ ] R15: VoiceOver — "오늘의 한 가지" 카드 = "오늘의 한 가지, {title}, {duration}, {level}" (AC15)
- [ ] R16: 모든 카드(오늘의 한 가지, 학습 경로 4개, 용어 사전)의 hit target ≥ 44×44pt (AC16)
- [ ] R17: `streakDays` 배지 VoiceOver = "연속 학습 {n}일" (Non-func)
- [ ] R18: 학습 경로 카드 VoiceOver = "{name} 코스, {lessonCount}강, 진행률 {percent}%" (Non-func)
- [ ] R19: 용어 사전 카드 VoiceOver = "용어 사전, 명리학 용어 {count}개" (Non-func)
- [ ] R20: 좌우 16pt padding, 카드 간 8pt 간격, 섹션 간 18pt 상단 마진, DesignTokens 재사용 (Non-func)
- [ ] R21: `MockSajuLearningPathProvider` 기본값: streakDays=3, featuredLesson=(id:"L-TEN-001", "십성이란 무엇인가?", "3분", "초급"), coursePaths=[(입문,7,1.0),(오행,5,0.6),(십성,8,0.3),(대운,6,0.0)], glossaryTermCount=120

---

## Implementation Steps

- [ ] S1: `SajuLearningPathProviding.swift` — `FeaturedLesson` struct, `CoursePath` struct 추가; 프로토콜에 `streakDays`, `featuredLesson`, `coursePaths`, `glossaryTermCount` 4개 프로퍼티 추가; protocol extension default 구현(`streakDays` → `weeklyProgress.streakDays`, `coursePaths` → `courses` 매핑); `MockSajuLearningPathProvider`에 `featuredLesson`, `glossaryTermCount` 저장 프로퍼티 및 mock 기본값 완성; 빌드 및 기존 T10~T12 통과 확인
- [ ] S2: `BelowFold/SajuStudySectionHeaderView.swift` 신규 — `streakDays: Int`, `onAllTap: () -> Void`; HStack 레이아웃(헤더 텍스트 + 스트릭 pill + Spacer + "전체 ›" 버튼); `streakDays > 0` 조건부 배지; accessibility identifiers 및 VoiceOver label 적용
- [ ] S3: `BelowFold/SajuFeaturedLessonCardView.swift` 신규 — `lesson: FeaturedLesson`, `onTap: () -> Void`; HStack(50×50 placeholder + VStack 3줄); `Button(action: onTap)` 전체 감쌈; `minHeight: 44`; `accessibilityElement(children: .ignore)` + label 설정; identifier `"SajuFeaturedLessonCard"`
- [ ] S4: `BelowFold/SajuCourseCardView.swift` 신규 — `coursePath: CoursePath?`, `slotName: String`, `onTap: () -> Void`; locked 상태(nil) → `gray2` 배경 + "-강"; `GeometryReader` 진행률 바(높이 3pt, clamp 0…1); `minHeight: 44`; VoiceOver label; identifier `"SajuCourseCard_\(slotName)"`
- [ ] S5: `BelowFold/SajuCourseGridView.swift` 신규 — `coursePaths: [CoursePath]`, `onTap: () -> Void`; `fixedOrder = ["입문","오행","십성","대운"]`; 이름 매칭으로 각 슬롯 CoursePath 조회(없으면 nil); `LazyVGrid` 2-column spacing: 8; identifier `"SajuCourseGrid"`
- [ ] S6: `BelowFold/SajuGlossaryCardView.swift` 신규 — `glossaryTermCount: Int`; HStack(32×32 placeholder "A" + VStack 2줄 + Spacer + "›"); count 조건 subtitle; `Button(action: { /* no-op */ })`; `.accessibilityHint("준비중")`; identifier `"SajuGlossaryCard"`
- [ ] S7: `BelowFold/SajuStudySectionView.swift` 신규 — `provider: any SajuLearningPathProviding`, `onNavigate: (SajuRoute) -> Void`; VStack(spacing:12)에 Block A~E 조립; `DisclaimerView()` 재사용; `.padding(.horizontal, 16)`; identifier `"SajuStudySection"`
- [ ] S8: `SajuTabContentView.swift` 수정 — `learningPathProvider: any SajuLearningPathProviding` 파라미터 추가; `Spacer(minLength: 32)` → `SajuStudySectionView(...)` 교체; `.padding(.top, 18)` 적용
- [ ] S9: `SajuTabView.swift` 수정 — `SajuTabContentView` 초기화 시 `learningPathProvider: deps.learningPath` 전달; 빌드 확인
- [ ] S10: 런치 인수 처리 — `WoontechApp` 진입 시 `ProcessInfo` 인수 `-sajuStreakDays` / `-sajuFeaturedLessonNil` 읽어 `SajuTabDependencies` mock 오버라이드 구현 (UI 테스트 TU-B03, TU-B08 지원)
- [ ] S11: `WoontechTests/Saju/SajuBelowFoldTests.swift` 유닛 테스트 작성 (TB-01 ~ TB-25)
- [ ] S12: `WoontechUITests/Saju/SajuBelowFoldUITests.swift` UI 테스트 작성 (TU-B01 ~ TU-B21)

---

## Tests

### Unit Tests (`WoontechTests/Saju/SajuBelowFoldTests.swift`)

- [ ] T-TB-01 (unit): `test_mockProvider_streakDays_is3` — `MockSajuLearningPathProvider().streakDays == 3` (AC2)
- [ ] T-TB-02 (unit): `test_mockProvider_featuredLesson_notNil` — `featuredLesson != nil` (AC4)
- [ ] T-TB-03 (unit): `test_mockProvider_featuredLesson_title_십성이란무엇인가` — title == "십성이란 무엇인가?" (AC4)
- [ ] T-TB-04 (unit): `test_mockProvider_featuredLesson_duration_3분_level_초급` — durationLabel, levelLabel 검증 (AC4)
- [ ] T-TB-05 (unit): `test_mockProvider_featuredLesson_id_LTEN001` — id == "L-TEN-001" (AC5)
- [ ] T-TB-06 (unit): `test_mockProvider_coursePaths_count_is4` — `coursePaths.count == 4` (AC7)
- [ ] T-TB-07 (unit): `test_mockProvider_coursePaths_names_fixed` — names == ["입문","오행","십성","대운"] 순서 포함 (AC7)
- [ ] T-TB-08 (unit): `test_mockProvider_coursePaths_progress_inRange` — 모든 progress ∈ [0.0, 1.0] (AC8)
- [ ] T-TB-09 (unit): `test_mockProvider_glossaryTermCount_is120` — `glossaryTermCount == 120` (AC10)
- [ ] T-TB-10 (unit): `test_courseGrid_fixedOrder_입문오행십성대운` — `SajuCourseGridView` 내부 `fixedOrder` 배열 검증 (AC7)
- [ ] T-TB-11 (unit): `test_courseGrid_missingCourse_usesLockSlot` — coursePaths=[] 주입 → 4슬롯 nil(locked) (AC7)
- [ ] T-TB-12 (unit): `test_progressBar_clamp_above1` — progress=1.5 → clamp=1.0 (AC8)
- [ ] T-TB-13 (unit): `test_progressBar_clamp_below0` — progress=-0.5 → clamp=0.0 (AC8)
- [ ] T-TB-14 (unit): `test_studyHeader_streakBadge_hidden_when0` — streakDays=0 → 배지 조건 분기 false (AC2)
- [ ] T-TB-15 (unit): `test_studyHeader_streakBadge_shown_when3` — streakDays=3 → 배지 조건 분기 true (AC2)
- [ ] T-TB-16 (unit): `test_studyHeader_allTap_fires_learnRoute` — onAllTap 콜백 캡처 → SajuRoute.learn (AC3)
- [ ] T-TB-17 (unit): `test_featuredLessonCard_tap_fires_lessonRoute_LTEN001` — onTap → SajuRoute.lesson(id: "L-TEN-001") (AC5)
- [ ] T-TB-18 (unit): `test_glossaryCard_subtitle_120개` — glossaryTermCount=120 → "명리학 용어 120개" (AC10)
- [ ] T-TB-19 (unit): `test_glossaryCard_subtitle_count0_no개suffix` — glossaryTermCount=0 → "명리학 용어" (AC10)
- [ ] T-TB-20 (unit): `test_disclaimer_text_contains_학습참고용` — DisclaimerView body에 "본 앱은 학습·참고용이며 투자 권유가 아닙니다." 포함 (AC12)
- [ ] T-TB-21 (unit): `test_studySection_featuredLessonNil_cardAbsent` — featuredLesson=nil → SajuFeaturedLessonCardView 렌더 조건 false (AC6)
- [ ] T-TB-22 (unit): `test_voiceOver_featuredLessonCard_accessibilityLabel` — label == "오늘의 한 가지, 십성이란 무엇인가?, 3분, 초급" (AC15)
- [ ] T-TB-23 (unit): `test_voiceOver_courseCard_accessibilityLabel` — 입문 카드 → "입문 코스, 7강, 진행률 100%" (Non-func)
- [ ] T-TB-24 (unit): `test_voiceOver_glossaryCard_accessibilityHint_준비중` — `.accessibilityHint == "준비중"` (AC11)
- [ ] T-TB-25 (unit): `test_glossaryCard_tap_doesNotFireNavigate` — onTap 콜백 발화 없음(no-op) 확인 (AC11)

### UI Tests (`WoontechUITests/Saju/SajuBelowFoldUITests.swift`)

- [ ] T-TU-B01 (ui): `test_studySection_exists_belowAboveFold` — 스크롤 후 `"SajuStudySection"` 존재 & 원국/카테고리 카드도 존재 (AC1)
- [ ] T-TU-B02 (ui): `test_streakBadge_visibleWhenDefault` — `"SajuStreakBadge"` 존재, label에 "🔥 연속 3일" 포함 (AC2)
- [ ] T-TU-B03 (ui): `test_streakBadge_hidden_when_streakDays0` — `-sajuStreakDays 0` env 주입 시 `"SajuStreakBadge"` 미존재 (AC2)
- [ ] T-TU-B04 (ui): `test_allButton_tap_pushesLearnRoute` — `"SajuStudyAllButton"` 탭 → `"SajuPlaceholderDestination_learn"` 노출 (AC3)
- [ ] T-TU-B05 (ui): `test_featuredLessonCard_exists_withDefaultMock` — `"SajuFeaturedLessonCard"` 존재, label에 "십성이란 무엇인가?" 포함 (AC4)
- [ ] T-TU-B06 (ui): `test_featuredLessonCard_label_contains_3분_초급` — card.label에 "3분", "초급" 포함 (AC4)
- [ ] T-TU-B07 (ui): `test_featuredLessonCard_tap_pushesLesson_LTEN001` — 탭 → `"SajuPlaceholderDestination_lesson"` + Identifier label "L-TEN-001" (AC5)
- [ ] T-TU-B08 (ui): `test_featuredLessonCard_absent_whenLessonNil` — `-sajuFeaturedLessonNil 1` env → `"SajuFeaturedLessonCard"` 미존재 & 그리드가 헤더 바로 아래 위치 (AC6)
- [ ] T-TU-B09 (ui): `test_courseGrid_fourCardsExist` — `"SajuCourseCard_입문"` 등 4개 버튼 존재 (AC7)
- [ ] T-TU-B10 (ui): `test_courseGrid_order_fixed` — 입문 frame.minY ≤ 오행 ≤ 십성 ≤ 대운 (AC7)
- [ ] T-TU-B11 (ui): `test_courseCard_introProgress_100percent` — `"SajuCourseCard_입문"` label에 "100%" 포함 (AC8)
- [ ] T-TU-B12 (ui): `test_courseCard_daewoonProgress_0percent` — `"SajuCourseCard_대운"` label에 "0%" 포함 (AC8)
- [ ] T-TU-B13 (ui): `test_courseCard_tap_pushesLearn` — `"SajuCourseCard_입문"` 탭 → `"SajuPlaceholderDestination_learn"` (AC9)
- [ ] T-TU-B14 (ui): `test_glossaryCard_subtitle_120개` — `"SajuGlossaryCard"` 존재, label에 "명리학 용어 120개" (AC10)
- [ ] T-TU-B15 (ui): `test_glossaryCard_tap_noNavigation` — 탭 후 `"SajuStudySection"` 여전히 최상위(path 변화 없음) (AC11)
- [ ] T-TU-B16 (ui): `test_disclaimer_text_visible` — `"DisclaimerText"` 존재 & label에 "본 앱은 학습·참고용이며" 포함 (AC12)
- [ ] T-TU-B17 (ui): `test_tabBar_active_index2` — `app.tabBars.buttons["사주 탭"].isSelected == true` (AC13)
- [ ] T-TU-B18 (ui): `test_dynamicType_xl_gridCards_noTruncation` — XL DT env 주입 → 카드 height > 44 & 4개 모두 존재 (AC14)
- [ ] T-TU-B19 (ui): `test_voiceOver_featuredLessonCard_accessibilityLabel` — card.label == "오늘의 한 가지, 십성이란 무엇인가?, 3분, 초급" (AC15)
- [ ] T-TU-B20 (ui): `test_hitTarget_allCards_minHeight44` — FeaturedLesson, 4 course cards, Glossary card frame.height ≥ 44 (AC16)
- [ ] T-TU-B21 (ui): `test_hitTarget_allCards_minWidth44` — 동일 카드 frame.width ≥ 44 (AC16)
