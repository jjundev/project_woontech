# Implementation Checklist — WF4-07 레슨 상세 (학습 경험)

## Requirements (from spec)

- [ ] R1: WF4-06 / WF4-03 / WF4-05 어느 진입점에서든 `SajuRoute.lesson(id:)` push 시 `SajuLessonView`가 렌더된다 (AC#1)
- [ ] R2: NavBar 타이틀에 `"{number}강 · {title}"` 형식 표시, 길이 초과 시 말줄임 (AC#2)
- [ ] R3: NavBar 우측에 muted `"{currentIndex}/{totalCount}"` 형식 텍스트 표시 (AC#3)
- [ ] R4: 진행 바 채움 너비 = `min(currentIndex / totalCount, 1.0) × 100%` 비율 (AC#4)
- [ ] R5: `currentIndex > totalCount` 시 진행 바 100%로 clamp (AC#5)
- [ ] R6: 화면 본문에 sectionLabel, headline, conceptBox, diagramPlaceholderLabel이 provider 값과 일치 (AC#6)
- [ ] R7: 인라인 퀴즈 옵션 박스 항상 4개, `quiz.choices` 순서 준수; choices 길이 ≠ 4 시 precondition 실패 (AC#7)
- [ ] R8: 선택 전 모든 옵션 박스 회색 테두리 + 흰 배경, "다음 강의" CTA 비활성 (AC#8)
- [ ] R9: 정답 선택 시 해당 옵션만 ink 테두리 + gray 배경, 나머지는 회색 유지, CTA 활성화 (AC#9)
- [ ] R10: 오답 선택 시 해당 옵션 빨강 테두리 + 연한 빨강 배경, 정답 옵션도 ink 테두리 + gray 배경, CTA 활성화 (AC#10)
- [ ] R11: 한 번 선택 후 다른 옵션 탭 시 상태 변하지 않음 (재선택 불가) (AC#11)
- [ ] R12: `nextLessonId != nil` 상태에서 CTA 탭 시 NavigationStack path 마지막 element를 `SajuRoute.lesson(id: nextLessonId)`로 교체 (이전 레슨 stack 미잔류) (AC#12)
- [ ] R13: `nextLessonId == nil` 시 CTA 라벨 "학습 완료", 탭 시 stack pop → WF4-06 복귀 (AC#13)
- [ ] R14: 알려지지 않은 id → fallback "준비중" lesson 렌더, 크래시 없음, 퀴즈 영역 숨김/비활성 (AC#14)
- [ ] R15: `SajuLessonProviding`은 `SajuLearningPathProviding`과 별개 프로토콜 (컴파일 타임 분리) (AC#15)
- [ ] R16: VoiceOver 접근성 레이블 — NavBar 타이틀 `"{number}강, {title}"`, 우측 `"현재 {currentIndex}강, 총 {totalCount}강"`, 진행 바 `"진행률 {percent}%"`, 다이어그램 placeholder `"다이어그램 자리, {label}"`, 퀴즈 카드 `"퀴즈, {question}"`, 옵션 `"{symbol}"`, 정답/오답 옵션 accessibilityValue `"정답"`/`"오답"` (AC#16)
- [ ] R17: 옵션 박스 hit target ≥ 44×44pt, "다음 강의" CTA hit target ≥ 44×44pt (AC#17)
- [ ] R18: Dynamic Type XL에서 headline / conceptBox / question / 옵션 텍스트 wrapping, 진행 바 두께 3pt 유지 (AC#18)

## Implementation Steps

- [ ] S1: `SajuLessonProviding.swift` 전면 재작성 — `Choice`, `Quiz`, `Lesson`(+`isFallback`), `SajuLessonProviding` 프로토콜, `MockSajuLessonProvider` (기본값 + fallback + "L-OH-LAST" 케이스). `SajuTabDependenciesTests`의 `StubSajuLessonProvider` 동시 수정 → 컴파일 통과
- [ ] S2: `DesignTokens.swift`에 퀴즈 색상 토큰 4개 추가 (`quizCorrectBorder`, `quizCorrectBackground`, `quizIncorrectBorder`, `quizIncorrectBg`) → 컴파일 통과, 기존 토큰 불변
- [ ] S3: `SajuLessonView.swift` 뼈대 작성 — struct 선언, `lesson: Lesson`, `onReplaceTop: (SajuRoute) -> Void`, `@Environment(\.dismiss)`, `@State var selectedChoiceIndex: Int?`, 최소 ScrollView+VStack body → Xcode preview 렌더
- [ ] S4: NavBar + 진행 바 구현 — `navigationTitle`, `.toolbar` trailing, 진행 바 3pt + GeometryReader, `static func progressRatio(currentIndex:totalCount:)`, `static func progressBarA11yLabel(current:total:)`, VoiceOver 레이블 적용
- [ ] S5: 본문 레이아웃 구현 — sectionLabel(9pt muted, 6pt 마진), headline(17pt bold, 14pt 마진), `ConceptBoxView`(gray 배경, 16pt padding, radius 8, 11pt 본문, 14pt 마진), `DiagramPlaceholderView`(200×140pt, 중앙 정렬, `"다이어그램 자리, {label}"` accessibilityLabel)
- [ ] S6: 인라인 퀴즈 카드 구현 — `QuizCardView`, 헤더(Q 라벨+quiz.label), question(12pt bold), `ChoiceOptionView` ForEach + `precondition(count==4)`, `static func choiceAppearance(index:selected:correct:)`, 탭 핸들러(guard + selectedChoiceIndex 세팅), `static func quizA11yLabel(question:)`, `static func choiceA11yValue(index:selected:correct:)`, fallback 시 카드 숨김
- [ ] S7: 하단 고정 CTA 영역 구현 — `BottomCTABarView`, 1pt 구분선(line3), 흰 배경, 라벨 조건부("다음 강의"/"학습 완료"), 비활성 시 dim+disabled, 탭 시 replace/pop, `.frame(minHeight: 44)`, `SajuLessonNextCTA` accessibilityIdentifier
- [ ] S8: `SajuRouteDestinations.swift` 업데이트 — `onReplaceTop: @escaping (SajuRoute) -> Void` 파라미터 추가, `.lesson(id:)` case에서 `SajuLessonView` 연결 → 컴파일 통과
- [ ] S9: `SajuTabView.swift` 업데이트 — `onReplaceTop` 클로저 전달(removeLast+append), UITest push 버튼 3개(`SajuNavPush_lessonLOH003`, `SajuNavPush_lessonNoNext`, `SajuNavPush_lessonUnknownId`) 보강 → 컴파일 통과
- [ ] S10: `WoontechApp.swift` launch args 파싱 — `-sajuLessonNoNextId` 파싱, `MockSajuLessonProvider`의 "L-OH-LAST" 케이스 사용해 `SajuTabDependencies` 조립 → 컴파일 통과
- [ ] S11: Unit Tests 작성 (`SajuLessonTests.swift`) — §5의 TL07-01 ~ TL07-32 모두 구현
- [ ] S12: UI Tests 작성 (`SajuLessonUITests.swift`) — §6의 TU-LS01 ~ TU-LS24 모두 구현

## Tests

### Unit Tests (`WoontechTests/Saju/SajuLessonTests.swift`)

- [ ] T-U01 (unit): `test_mockProvider_defaultLesson_id` — `MockSajuLessonProvider().lesson(id: "L-OH-003").id == "L-OH-003"` (AC#6)
- [ ] T-U02 (unit): `test_mockProvider_defaultLesson_numberAndTitle` — number=3, title="오행의 의미" (AC#2)
- [ ] T-U03 (unit): `test_mockProvider_defaultLesson_currentIndex_totalCount` — currentIndex=3, totalCount=7 (AC#3, AC#4)
- [ ] T-U04 (unit): `test_mockProvider_defaultLesson_sectionLabel_headline` — sectionLabel, headline 값 일치 (AC#6)
- [ ] T-U05 (unit): `test_mockProvider_defaultLesson_quizChoicesCount_is4` — `quiz.choices.count == 4` (AC#7)
- [ ] T-U06 (unit): `test_mockProvider_defaultLesson_correctIndex_is2` — `quiz.correctIndex == 2` (AC#7)
- [ ] T-U07 (unit): `test_mockProvider_defaultLesson_nextLessonId_notNil` — `nextLessonId == "L-OH-004"` (AC#12)
- [ ] T-U08 (unit): `test_progressRatio_3of7_approx42857` — `progressRatio(3, 7) ≈ 0.42857` (AC#4)
- [ ] T-U09 (unit): `test_progressRatio_clamp_above1` — `progressRatio(8, 7) == 1.0` (AC#5)
- [ ] T-U10 (unit): `test_progressRatio_totalZero_returns0` — `progressRatio(0, 0) == 0.0`
- [ ] T-U11 (unit): `test_choiceAppearance_beforeSelection_allGray` — selected=nil → border=gray2, bg=white, weight=regular (AC#8)
- [ ] T-U12 (unit): `test_choiceAppearance_correctSelected_inkBorder` — selected=2, correct=2, index=2 → ink border, gray bg (AC#9)
- [ ] T-U13 (unit): `test_choiceAppearance_correctSelected_otherStayGray` — selected=2, correct=2, index≠2 → gray2 border (AC#9)
- [ ] T-U14 (unit): `test_choiceAppearance_incorrectSelected_redBorder` — selected=0, correct=2, index=0 → red border + red bg (AC#10)
- [ ] T-U15 (unit): `test_choiceAppearance_incorrectSelected_correctHighlighted` — selected=0, correct=2, index=2 → ink border + gray bg (AC#10)
- [ ] T-U16 (unit): `test_choiceAppearance_incorrectSelected_otherGray` — selected=0, correct=2, index=1 → gray2 border (AC#10)
- [ ] T-U17 (unit): `test_ctaLabel_nextLessonIdNotNil_isDaeum` — `nextLessonId != nil` → label "다음 강의" (AC#12)
- [ ] T-U18 (unit): `test_ctaLabel_nextLessonIdNil_isHakseup` — `nextLessonId == nil` → label "학습 완료" (AC#13)
- [ ] T-U19 (unit): `test_ctaActive_onlyAfterSelection` — nil → disabled; non-nil → enabled (AC#8, AC#9)
- [ ] T-U20 (unit): `test_noReselect_afterFirstSelection` — `selectedChoiceIndex` 첫 선택 이후 불변 (AC#11)
- [ ] T-U21 (unit): `test_mockProvider_unknownId_returnsFallback` — 알 수 없는 id → `isFallback == true` (AC#14)
- [ ] T-U22 (unit): `test_fallbackLesson_quizChoicesStillCount4` — fallback `quiz.choices.count == 4` (AC#14)
- [ ] T-U23 (unit): `test_lessonProviding_separateFrom_learningPathProviding` — `XCTAssertFalse(MockSajuLessonProvider() is any SajuLearningPathProviding)` (AC#15)
- [ ] T-U24 (unit): `test_mockProvider_navbarTitle_format` — `"\(number)강 · \(title)" == "3강 · 오행의 의미"` (AC#2)
- [ ] T-U25 (unit): `test_mockProvider_navbarTrailing_format` — `"\(currentIndex)/\(totalCount)" == "3/7"` (AC#3)
- [ ] T-U26 (unit): `test_voiceOver_navbarTitle_accessibilityLabel` — `"\(number)강, \(title)" == "3강, 오행의 의미"` (AC#16)
- [ ] T-U27 (unit): `test_voiceOver_navbarTrailing_accessibilityLabel` — `"현재 \(currentIndex)강, 총 \(totalCount)강" == "현재 3강, 총 7강"` (AC#16)
- [ ] T-U28 (unit): `test_voiceOver_progressBar_accessibilityLabel` — `progressBarA11yLabel(current:3, total:7) == "진행률 43%"` (AC#16)
- [ ] T-U29 (unit): `test_voiceOver_diagramPlaceholder_accessibilityLabel` — `"다이어그램 자리, 상생·상극 다이어그램"` (AC#16)
- [ ] T-U30 (unit): `test_voiceOver_quizChoice_symbol_isAccessibilityLabel` — `choices[2].symbol == "金"` (AC#16)
- [ ] T-U31 (unit): `test_voiceOver_quizCard_accessibilityLabel` — `quizA11yLabel(question: "水를 생(生)하는 오행은?") == "퀴즈, 水를 생(生)하는 오행은?"` (AC#16)
- [ ] T-U32 (unit): `test_voiceOver_choiceAccessibilityValue` — `choiceA11yValue(2, selected:2, correct:2) == "정답"`, `choiceA11yValue(0, selected:0, correct:2) == "오답"`, `choiceA11yValue(1, selected:0, correct:2) == ""`, `choiceA11yValue(0, selected:nil, correct:2) == ""` (AC#16)

### UI Tests (`WoontechUITests/Saju/SajuLessonUITests.swift`)

- [ ] T-UI01 (ui): `test_navigate_fromLearnList_pushesLesson` — `SajuLearnListView`에서 `SajuLessonCard_L3` 탭 → `SajuLessonView` 등장 (AC#1)
- [ ] T-UI02 (ui): `test_navigate_fromSajuNavPush_pushesLesson` — UITest push 버튼 탭 → `SajuLessonView` 등장 (AC#1)
- [ ] T-UI03 (ui): `test_navBar_title_format` — navigationBars["3강 · 오행의 의미"] 존재 (AC#2)
- [ ] T-UI04 (ui): `test_navBar_trailing_progress_text` — staticTexts["3/7"] 존재 (AC#3)
- [ ] T-UI05 (ui): `test_progressBar_exists` — `SajuLessonProgressBar` 존재 (AC#4)
- [ ] T-UI06 (ui): `test_sectionLabel_binding` — `SajuLessonSectionLabel.label == "기본 개념"` (AC#6)
- [ ] T-UI07 (ui): `test_headline_binding` — `SajuLessonHeadline.label == "오행이란?"` (AC#6)
- [ ] T-UI08 (ui): `test_conceptBox_exists` — `SajuLessonConceptBox` 존재 (AC#6)
- [ ] T-UI09 (ui): `test_diagramPlaceholder_exists` — `SajuLessonDiagramPlaceholder` 존재 (AC#6)
- [ ] T-UI10 (ui): `test_quizCard_4choices_exist` — `SajuLessonQuizChoice_0`~`_3` 모두 존재 (AC#7)
- [ ] T-UI11 (ui): `test_ctaButton_initially_disabled` — `SajuLessonNextCTA.isEnabled == false` (AC#8)
- [ ] T-UI12 (ui): `test_correctChoice_tap_activatesCTA` — `SajuLessonQuizChoice_2` 탭 → `SajuLessonNextCTA.isEnabled == true` (AC#9)
- [ ] T-UI13 (ui): `test_incorrectChoice_tap_activatesCTA` — `SajuLessonQuizChoice_0` 탭 → `SajuLessonNextCTA.isEnabled == true` (AC#10)
- [ ] T-UI14 (ui): `test_secondTap_ignored` — `SajuLessonQuizChoice_2` 탭 후 `SajuLessonQuizChoice_1` 탭 → CTA 상태 불변 (AC#11)
- [ ] T-UI15 (ui): `test_nextCTA_nextId_replacesTop` — 정답 탭 후 CTA 탭 → 새 lesson으로 replace, Back 시 LearnList 복귀 (AC#12)
- [ ] T-UI16 (ui): `test_nextCTA_noNextId_label_is학습완료` — `-sajuLessonNoNextId` arg → CTA label "학습 완료" (AC#13)
- [ ] T-UI17 (ui): `test_nextCTA_noNextId_tap_popsToLearnList` — `-sajuLessonNoNextId` arg, 정답 탭 후 CTA 탭 → `SajuLearnListView` 복귀 (AC#13)
- [ ] T-UI18 (ui): `test_unknownId_fallback_noCrash` — `SajuNavPush_lessonUnknownId` 탭 → 크래시 없음, 타이틀에 "준비중" 포함 (AC#14)
- [ ] T-UI19 (ui): `test_hitTarget_choices_minSize44` — `SajuLessonQuizChoice_0`~`_3` 각 frame.height ≥ 44 (AC#17)
- [ ] T-UI20 (ui): `test_hitTarget_ctaButton_minSize44` — `SajuLessonNextCTA` frame.height ≥ 44 (AC#17)
- [ ] T-UI21 (ui): `test_dynamicType_xl_textNotTruncated` — `UIContentSizeCategoryOverride=XL` → 텍스트 존재, 진행 바 높이 3pt 유지 (AC#18)
- [ ] T-UI22 (ui): `test_backButton_pops_toLearnList` — Back 버튼 탭 → `SajuLearnListView` 복귀 (AC#1)
- [ ] T-UI23 (ui): `test_voiceOver_progressBar_label` — `SajuLessonProgressBar.label` contains "진행률" and percent string (AC#16)
- [ ] T-UI24 (ui): `test_voiceOver_diagramPlaceholder_label` — `SajuLessonDiagramPlaceholder.label` contains "다이어그램 자리" (AC#16)
