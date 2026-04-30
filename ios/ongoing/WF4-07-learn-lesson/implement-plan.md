# implement-plan.md — WF4-07 레슨 상세 (학습 경험)
## Version 3

---

## 1. Goal

`SajuRoute.lesson(id:)` 라우트의 placeholder를 `SajuLessonView`로 교체하여, 진행 바·개념 박스·다이어그램 placeholder·인라인 퀴즈·하단 CTA를 포함하는 레슨 상세 화면을 구현한다. 퀴즈 정답 선택 후 "다음 강의" CTA로 학습 흐름을 이어가며, NavigationStack path 마지막 element를 교체하는 방식으로 이전 레슨이 스택에 남지 않도록 한다.

---

## 2. Affected Files

### 신규 파일

| 경로 | 설명 |
|------|------|
| `Woontech/Features/Saju/Learn/SajuLessonView.swift` | 레슨 상세 메인 뷰 + 하위 컴포넌트 |
| `WoontechTests/Saju/SajuLessonTests.swift` | WF4-07 unit tests |
| `WoontechUITests/Saju/SajuLessonUITests.swift` | WF4-07 UI tests |

### 수정 파일

| 경로 | 변경 내용 |
|------|----------|
| `Woontech/Features/Saju/Providers/SajuLessonProviding.swift` | 프로토콜·모델·mock 전면 교체 |
| `Woontech/Shared/DesignTokens.swift` | 퀴즈 정답/오답 색상 토큰 추가 |
| `Woontech/Features/Saju/SajuRouteDestinations.swift` | `.lesson(id:)` → `SajuLessonView` 교체, `onReplaceTop` 파라미터 추가 |
| `Woontech/Features/Saju/SajuTabView.swift` | `onReplaceTop` 클로저 전달, UITest push 버튼 보강 |
| `Woontech/App/WoontechApp.swift` | 레슨 mock launch args 파싱 및 `SajuTabDependencies` 조립 |
| `WoontechTests/Saju/SajuTabDependenciesTests.swift` | `StubSajuLessonProvider` + T4 어서션을 새 프로토콜에 맞게 수정 |

---

## 3. Data Model / State Changes

### 3-1. `SajuLessonProviding.swift` 전면 재작성

기존 `lessonTitle(forId:) -> String?` 시그니처를 제거하고 아래로 교체한다.

```
Choice       { symbol: String }
Quiz         { label: String, question: String, choices: [Choice], correctIndex: Int }
Lesson       { id: String, number: Int, title: String,
               currentIndex: Int, totalCount: Int,
               sectionLabel: String, headline: String,
               conceptBox: String, diagramPlaceholderLabel: String,
               quiz: Quiz,
               nextLessonId: String? }

protocol SajuLessonProviding {
    func lesson(id: String) -> Lesson
}
```

- `choices.count != 4` 인 Lesson은 precondition 실패(뷰에서 방어).
- 알려지지 않은 id → fallback `Lesson` 반환 (title "준비중", quiz 없음 처리).
  - Fallback lesson의 `quiz.choices`는 길이 4를 유지하되 `symbol`은 빈 문자열 허용; 뷰는 `isFallback` 플래그 또는 별도 타입으로 퀴즈 영역을 숨긴다.
  - 단순화: fallback은 정상 Lesson이되 `quiz.choices`가 4개 dummy Choice이고 별도 `isFallback: Bool` 필드로 퀴즈를 숨긴다.

`MockSajuLessonProvider` 기본값:

```
id "L-OH-003", number 3, title "오행의 의미"
currentIndex 3, totalCount 7
sectionLabel "기본 개념", headline "오행이란?"
conceptBox "오행은 木·火·土·金·水의 다섯 요소로, 세상 모든 것을 다섯 기운의 흐름으로 설명하는 명리학의 기본 틀입니다."
diagramPlaceholderLabel "상생·상극 다이어그램"
quiz: label "간단 체크", question "水를 생(生)하는 오행은?",
      choices [木, 火, 金, 土], correctIndex 2
nextLessonId "L-OH-004"
```

`MockSajuLessonProvider`는 `id`로 조회해 알려진 id면 기본값을, 모르는 id면 fallback lesson을 반환한다.

### 3-2. DesignTokens 추가

```swift
// MARK: - 퀴즈 색상 토큰 (WF4-07)
static let quizCorrectBorder     = ink           // 정답 테두리
static let quizCorrectBackground = gray          // 정답 배경
static let quizIncorrectBorder   = absentRed     // 오답 테두리 (fireColor 재사용)
static let quizIncorrectBg       = absentRedLight // 오답 배경 (연한 빨강 재사용)
```

### 3-3. `SajuLessonView` 내부 State

```swift
@State private var selectedChoiceIndex: Int? = nil
```

- `nil` → 미선택 (CTA 비활성)
- `non-nil` → 선택 완료 (CTA 활성)
- 선택 후 재선택 불가: `guard selectedChoiceIndex == nil else { return }` in tap handler

퀴즈 옵션 박스 렌더 로직 (pure function, testable):

```swift
static func choiceAppearance(
    index: Int,
    selected: Int?,
    correct: Int
) -> (border: Color, background: Color, weight: Font.Weight)
```

진행 바 비율 (testable static):

```swift
static func progressRatio(currentIndex: Int, totalCount: Int) -> Double {
    guard totalCount > 0 else { return 0 }
    return min(Double(currentIndex) / Double(totalCount), 1.0)
}
```

### 3-4. 네비게이션 콜백 추가

`sajuRouteDestination(for:deps:onNavigate:)` 시그니처에 `onReplaceTop: @escaping (SajuRoute) -> Void` 파라미터 추가.

`SajuTabView`에서 전달:

```swift
onReplaceTop: { route in
    if !navigationPath.isEmpty { navigationPath.removeLast() }
    navigationPath.append(route)
}
```

`SajuLessonView`는 `@Environment(\.dismiss)` 로 pop, `onReplaceTop` 클로저로 replace를 수행한다.

---

## 4. Implementation Steps

각 스텝은 컴파일·테스트 가능한 단위로 분리된다.

### Step 1 — 데이터 모델 교체 (`SajuLessonProviding.swift`)
- `Choice`, `Quiz`, `Lesson` struct 선언 (각 필드 포함, `isFallback: Bool` 포함)
- `SajuLessonProviding` 프로토콜 재정의: `func lesson(id: String) -> Lesson`
- `MockSajuLessonProvider` 재작성: 기본값 lesson + fallback lesson 반환 로직
- **검증**: 기존 `SajuTabDependenciesTests` 의 `StubSajuLessonProvider`를 새 프로토콜에 맞게 수정 → 컴파일 통과

### Step 2 — DesignTokens 퀴즈 색상 토큰 추가
- `DesignTokens.swift` 에 4개 alias 상수 추가 (기존 색상 재사용)
- **검증**: 컴파일 통과, 기존 토큰 참조 불변

### Step 3 — `SajuLessonView` 뼈대 작성
- 파일 생성, `SajuLessonView: View` struct 선언
- 프로퍼티: `let lesson: Lesson`, `let onReplaceTop: (SajuRoute) -> Void`
- `@Environment(\.dismiss) var dismiss`
- `@State private var selectedChoiceIndex: Int? = nil`
- `body`: 최소 `ScrollView + VStack` 구조만, toolbar placeholder
- **검증**: 컴파일 통과, Xcode preview 렌더

### Step 4 — NavBar · 진행 바 구현
- `navigationTitle("{number}강 · {title}")` inline + `.lineLimit(1)` + truncation
- `.toolbar` trailing item: muted text "{currentIndex}/{totalCount}"
- 진행 바: NavBar 직하단 GeometryReader `Rectangle` fill, 높이 3pt, `clamp(0...1)`
- `static func progressRatio(currentIndex:totalCount:)` 추출
- `static func progressBarA11yLabel(current: Int, total: Int) -> String` 추출 — `"진행률 \(Int((progressRatio(currentIndex:current, totalCount:total) * 100).rounded()))%"` 형식
- VoiceOver: 진행 바 `.accessibilityLabel(progressBarA11yLabel(current:total:))`, NavBar 타이틀 `.accessibilityLabel("\(number)강, \(title)")`, trailing `.accessibilityLabel("현재 \(currentIndex)강, 총 \(totalCount)강")`
- **검증**: Unit tests `progressRatio` 로직 (TL07-08, TL07-09) + `progressBarA11yLabel` (TL07-28) + NavBar 접근성 라벨 형식 (TL07-26, TL07-27)

### Step 5 — 본문 레이아웃 구현 (sectionLabel · headline · conceptBox · diagramPlaceholder)
- 좌우 18pt padding ScrollView 내부 VStack
- sectionLabel (9pt muted), 6pt 마진
- headline (17pt bold), 14pt 마진
- `ConceptBoxView` 서브뷰: gray 배경, 16pt padding, radius 8, 11pt 본문
- 14pt 마진
- `DiagramPlaceholderView` 서브뷰: 200×140pt 박스, 중앙 정렬, 라벨 텍스트
- VoiceOver: `DiagramPlaceholderView`에 `.accessibilityLabel("다이어그램 자리, \(diagramPlaceholderLabel)")` 지정 (TL07-29, TU-LS24)
- VoiceOver identifier 및 기타 accessibilityLabel 세팅
- **검증**: Xcode preview로 레이아웃 확인

### Step 6 — 인라인 퀴즈 카드 구현
- `QuizCardView` 서브뷰 (padding 14pt)
- 헤더: 사각 라벨 박스("Q" 텍스트, border) + muted `quiz.label`
- question (12pt bold)
- `choices` ForEach — `precondition(quiz.choices.count == 4, ...)` 방어
- 각 옵션: `ChoiceOptionView` (Button 스타일, `symbol` 텍스트 좌측 정렬, `.frame(minHeight: 44)`)
- `static func choiceAppearance(index:selected:correct:)` 구현
- 탭 핸들러: `guard selectedChoiceIndex == nil` 후 `selectedChoiceIndex = index`
- fallback lesson 시 퀴즈 카드 숨김 (`.opacity(0)` 또는 `if !lesson.isFallback`)
- VoiceOver:
  - 퀴즈 카드 컨테이너(또는 헤더+question 묶음)에 `.accessibilityLabel(quizA11yLabel(question:quiz.question))` 지정. 헬퍼: `static func quizA11yLabel(question: String) -> String { "퀴즈, \(question)" }` (TL07-31)
  - 각 `ChoiceOptionView`에 `.accessibilityValue(choiceA11yValue(index:i, selected:selectedChoiceIndex, correct:quiz.correctIndex))` 지정. 헬퍼: `static func choiceA11yValue(index: Int, selected: Int?, correct: Int) -> String` — 선택 전: `""`, 정답 강조: `"정답"`, 오답 선택: `"오답"`, 나머지: `""`. 이 값이 VoiceOver에서 "정답"/"오답" 트레잇 역할을 수행한다. (TL07-32)
- **검증**: `choiceAppearance`, `quizA11yLabel`, `choiceA11yValue` unit tests (TL07-31, TL07-32), preview에서 탭 interaction

### Step 7 — 하단 고정 CTA 영역 구현
- `VStack` → `ZStack(alignment: .bottom)` 구조로 감싸기
- `BottomCTABarView` 서브뷰: 1pt 구분선(line3) + 흰 배경 + Button
- 라벨: `nextLessonId == nil ? "학습 완료" : "다음 강의"`
- 비활성화: `selectedChoiceIndex == nil` → `.opacity(dim)`, `.disabled(true)`
- 탭:
  - `nextLessonId != nil` → `onReplaceTop(.lesson(id: nextLessonId))`
  - `nextLessonId == nil` → `dismiss()`
- hit target: `.frame(minHeight: 44)`
- VoiceOver identifier `SajuLessonNextCTA`
- **검증**: unit test(라벨·활성화 로직), preview

### Step 8 — 라우트 연결 (`SajuRouteDestinations.swift`)
- `sajuRouteDestination` 함수에 `onReplaceTop: @escaping (SajuRoute) -> Void` 파라미터 추가
- `.lesson(id:)` case: `SajuPlaceholderDestinationView` → `SajuLessonView(lesson: deps.lesson.lesson(id: id), onReplaceTop: onReplaceTop)`
- **검증**: 컴파일 통과

### Step 9 — `SajuTabView` 업데이트
- `sajuRouteDestination` 호출 시 `onReplaceTop` 클로저 전달 (removeLast + append)
- UITest push 버튼 보강 (세 버튼은 서로 다른 시나리오 담당; 이름과 용도를 1:1로 매핑):
  - `SajuNavPush_lessonLOH003` — `.lesson(id: "L-OH-003")` push (기본값 레슨, nextLessonId = "L-OH-004")
  - `SajuNavPush_lessonNoNext` — `.lesson(id: "L-OH-LAST")` push. `MockSajuLessonProvider`는 이 id를
    알려진 마지막 레슨(nextLessonId = nil)으로 반환한다. TU-LS16/TU-LS17에서 사용.
  - `SajuNavPush_lessonUnknownId` — `.lesson(id: "__unknown__")` push. 알려지지 않은 id → fallback
    "준비중" 레슨 반환. TU-LS18에서 사용.
- **검증**: 컴파일 통과, 기존 UITest push 버튼 불변

### Step 10 — `WoontechApp.swift` launch args 파싱 + `MockSajuLessonProvider` no-next 케이스
- `MockSajuLessonProvider`에 id `"L-OH-LAST"` 케이스 추가: 정상 레슨이되 `nextLessonId = nil`
  (SajuNavPush_lessonNoNext 버튼이 이 id를 push; TU-LS16/17이 이 경로를 사용)
- `-sajuLessonNoNextId` launch arg → `MockSajuLessonProvider`가 `"L-OH-LAST"` 반환하도록 조립
  (app-level 초기화 오버라이드)
- 위 args 가 있을 때 `SajuTabDependencies(lesson: overrideProvider)` 조립 후 `_sajuTabDeps` 초기화
- **검증**: 컴파일 통과

### Step 11 — Unit Test 작성 (`SajuLessonTests.swift`)
- spec 요건·AC 항목에 1:1 대응하는 테스트 함수 구현 (§5 참조)

### Step 12 — UI Test 작성 (`SajuLessonUITests.swift`)
- AC 항목에 대응하는 UI 테스트 함수 구현 (§6 참조)

---

## 5. Unit Test Plan

파일: `WoontechTests/Saju/SajuLessonTests.swift`

| ID | 메서드명 | 검증 내용 | 근거 |
|----|---------|----------|------|
| TL07-01 | `test_mockProvider_defaultLesson_id` | `MockSajuLessonProvider().lesson(id: "L-OH-003").id == "L-OH-003"` | AC#6 |
| TL07-02 | `test_mockProvider_defaultLesson_numberAndTitle` | number=3, title="오행의 의미" | AC#2 |
| TL07-03 | `test_mockProvider_defaultLesson_currentIndex_totalCount` | currentIndex=3, totalCount=7 | AC#3, AC#4 |
| TL07-04 | `test_mockProvider_defaultLesson_sectionLabel_headline` | sectionLabel, headline 일치 | AC#6 |
| TL07-05 | `test_mockProvider_defaultLesson_quizChoicesCount_is4` | `quiz.choices.count == 4` | AC#7 |
| TL07-06 | `test_mockProvider_defaultLesson_correctIndex_is2` | `quiz.correctIndex == 2` | AC#7 |
| TL07-07 | `test_mockProvider_defaultLesson_nextLessonId_notNil` | `nextLessonId == "L-OH-004"` | AC#12 |
| TL07-08 | `test_progressRatio_3of7_approx42857` | `progressRatio(currentIndex:3, totalCount:7) ≈ 0.42857` | AC#4 |
| TL07-09 | `test_progressRatio_clamp_above1` | `progressRatio(currentIndex:8, totalCount:7) == 1.0` | AC#5 |
| TL07-10 | `test_progressRatio_totalZero_returns0` | `progressRatio(currentIndex:0, totalCount:0) == 0.0` | — |
| TL07-11 | `test_choiceAppearance_beforeSelection_allGray` | selected=nil → border=gray2, bg=white, weight=regular (모든 index) | AC#8 |
| TL07-12 | `test_choiceAppearance_correctSelected_inkBorder` | selected=2, correct=2, index=2 → border=quizCorrectBorder(ink), bg=quizCorrectBackground(gray) | AC#9 |
| TL07-13 | `test_choiceAppearance_correctSelected_otherStayGray` | selected=2, correct=2, index≠2 → border=gray2 | AC#9 |
| TL07-14 | `test_choiceAppearance_incorrectSelected_redBorder` | selected=0, correct=2, index=0 → border=quizIncorrectBorder, bg=quizIncorrectBg | AC#10 |
| TL07-15 | `test_choiceAppearance_incorrectSelected_correctHighlighted` | selected=0, correct=2, index=2 → border=quizCorrectBorder, bg=quizCorrectBackground | AC#10 |
| TL07-16 | `test_choiceAppearance_incorrectSelected_otherGray` | selected=0, correct=2, index=1 → border=gray2 | AC#10 |
| TL07-17 | `test_ctaLabel_nextLessonIdNotNil_isDaeum` | `nextLessonId != nil` → label "다음 강의" | AC#12 |
| TL07-18 | `test_ctaLabel_nextLessonIdNil_isHakseup` | `nextLessonId == nil` → label "학습 완료" | AC#13 |
| TL07-19 | `test_ctaActive_onlyAfterSelection` | `selectedChoiceIndex == nil` → disabled; non-nil → enabled | AC#8, AC#9 |
| TL07-20 | `test_noReselect_afterFirstSelection` | `selectedChoiceIndex` 는 첫 선택 이후 변하지 않음 | AC#11 |
| TL07-21 | `test_mockProvider_unknownId_returnsFallback` | 알려지지 않은 id → `isFallback == true` | AC#14 |
| TL07-22 | `test_fallbackLesson_quizChoicesStillCount4` | fallback lesson `quiz.choices.count == 4` | AC#14 |
| TL07-23 | `test_lessonProviding_separateFrom_learningPathProviding` | 런타임 타입 체크로 프로토콜 분리 검증: `XCTAssertFalse(MockSajuLessonProvider() is any SajuLearningPathProviding)`. 이 어서션은 두 프로토콜이 서로 다른 타입 계층임을 확인한다. | AC#15 |
| TL07-24 | `test_mockProvider_navbarTitle_format` | `"\(number)강 · \(title)" == "3강 · 오행의 의미"` | AC#2 |
| TL07-25 | `test_mockProvider_navbarTrailing_format` | `"\(currentIndex)/\(totalCount)" == "3/7"` | AC#3 |
| TL07-26 | `test_voiceOver_navbarTitle_accessibilityLabel` | `"\(number)강, \(title)"` 형식 문자열 == "3강, 오행의 의미" (쉼표·공백 포함) | AC#16 |
| TL07-27 | `test_voiceOver_navbarTrailing_accessibilityLabel` | `"현재 \(currentIndex)강, 총 \(totalCount)강"` == "현재 3강, 총 7강" | AC#16 |
| TL07-28 | `test_voiceOver_progressBar_accessibilityLabel` | 순수 헬퍼 `progressBarA11yLabel(current:3, total:7)` → `"진행률 43%"` (percent 반올림) | AC#16 |
| TL07-29 | `test_voiceOver_diagramPlaceholder_accessibilityLabel` | `"다이어그램 자리, \(diagramPlaceholderLabel)"` == "다이어그램 자리, 상생·상극 다이어그램" | AC#16 |
| TL07-30 | `test_voiceOver_quizChoice_symbol_isAccessibilityLabel` | 각 Choice의 `symbol` 문자열이 해당 옵션 접근성 라벨로 사용됨: choices[2].symbol == "金" | AC#16 |
| TL07-31 | `test_voiceOver_quizCard_accessibilityLabel` | 순수 헬퍼 `quizA11yLabel(question: "水를 생(生)하는 오행은?")` → `"퀴즈, 水를 생(生)하는 오행은?"` | AC#16 |
| TL07-32 | `test_voiceOver_choiceAccessibilityValue` | `choiceA11yValue(index:2, selected:2, correct:2) == "정답"`, `choiceA11yValue(index:0, selected:0, correct:2) == "오답"`, `choiceA11yValue(index:1, selected:0, correct:2) == ""`, `choiceA11yValue(index:0, selected:nil, correct:2) == ""` | AC#16 |

---

## 6. UI Test Plan

파일: `WoontechUITests/Saju/SajuLessonUITests.swift`

공통 setup: `-resetOnboarding -openSajuTab` 실행 후 `SajuNavPush_lessonLOH003` 버튼 탭으로 `SajuLessonView` 진입.

### Accessibility Identifiers (뷰 계약)

| 식별자 | 종류 | 설명 |
|--------|------|------|
| `SajuLessonView` | `otherElements` | Color.clear 마커 |
| `SajuLessonProgressBar` | `otherElements` | 진행 바 컨테이너 |
| `SajuLessonSectionLabel` | `staticTexts` | sectionLabel 텍스트 |
| `SajuLessonHeadline` | `staticTexts` | headline 텍스트 |
| `SajuLessonConceptBox` | `otherElements` | 개념 박스 컨테이너 |
| `SajuLessonDiagramPlaceholder` | `otherElements` | 다이어그램 placeholder |
| `SajuLessonQuizCard` | `otherElements` | 퀴즈 카드 컨테이너 |
| `SajuLessonQuizChoice_0` … `_3` | `buttons` | 각 선택지 버튼 |
| `SajuLessonNextCTA` | `buttons` | 하단 CTA 버튼 |

### UI 테스트 목록

| ID | 메서드명 | 검증 내용 | AC# |
|----|---------|----------|-----|
| TU-LS01 | `test_navigate_fromLearnList_pushesLesson` | `SajuLearnListView`에서 `SajuLessonCard_L3` 탭 → `SajuLessonView` 등장 | AC#1 |
| TU-LS02 | `test_navigate_fromSajuNavPush_pushesLesson` | UITest push 버튼 탭 → `SajuLessonView` 등장 | AC#1 |
| TU-LS03 | `test_navBar_title_format` | navigationBars["3강 · 오행의 의미"] 존재 | AC#2 |
| TU-LS04 | `test_navBar_trailing_progress_text` | staticTexts["3/7"] 존재 | AC#3 |
| TU-LS05 | `test_progressBar_exists` | `SajuLessonProgressBar` 존재 | AC#4 |
| TU-LS06 | `test_sectionLabel_binding` | `SajuLessonSectionLabel.label == "기본 개념"` | AC#6 |
| TU-LS07 | `test_headline_binding` | `SajuLessonHeadline.label == "오행이란?"` | AC#6 |
| TU-LS08 | `test_conceptBox_exists` | `SajuLessonConceptBox` 존재 | AC#6 |
| TU-LS09 | `test_diagramPlaceholder_exists` | `SajuLessonDiagramPlaceholder` 존재 | AC#6 |
| TU-LS10 | `test_quizCard_4choices_exist` | `SajuLessonQuizChoice_0`~`_3` 모두 존재 | AC#7 |
| TU-LS11 | `test_ctaButton_initially_disabled` | `SajuLessonNextCTA.isEnabled == false` | AC#8 |
| TU-LS12 | `test_correctChoice_tap_activatesCTA` | `SajuLessonQuizChoice_2` 탭 → `SajuLessonNextCTA.isEnabled == true` | AC#9 |
| TU-LS13 | `test_incorrectChoice_tap_activatesCTA` | `SajuLessonQuizChoice_0` 탭 → `SajuLessonNextCTA.isEnabled == true` | AC#10 |
| TU-LS14 | `test_secondTap_ignored` | `SajuLessonQuizChoice_2` 탭 후 `SajuLessonQuizChoice_1` 탭 → CTA 상태 불변, 두 번째 탭 무시 | AC#11 |
| TU-LS15 | `test_nextCTA_nextId_replacesTop` | 정답 탭 후 CTA 탭 → 새 lesson 화면으로 replace (SajuLessonView 존재, Back으로 LearnList 복귀) | AC#12 |
| TU-LS16 | `test_nextCTA_noNextId_label_is학습완료` | `-sajuLessonNoNextId` arg → CTA label "학습 완료" | AC#13 |
| TU-LS17 | `test_nextCTA_noNextId_tap_popsToLearnList` | `-sajuLessonNoNextId` arg, 정답 탭 후 CTA 탭 → `SajuLearnListView` 복귀 | AC#13 |
| TU-LS18 | `test_unknownId_fallback_noCrash` | `SajuNavPush_lessonUnknownId` 탭 (id: "__unknown__") → 크래시 없이 뷰 등장, 타이틀에 "준비중" 포함 | AC#14 |
| TU-LS19 | `test_hitTarget_choices_minSize44` | `SajuLessonQuizChoice_0`~`_3` 각 frame.height ≥ 44 | AC#17 |
| TU-LS20 | `test_hitTarget_ctaButton_minSize44` | `SajuLessonNextCTA` frame.height ≥ 44 | AC#17 |
| TU-LS21 | `test_dynamicType_xl_textNotTruncated` | `UIContentSizeCategoryOverride=UICTContentSizeCategoryXL` → Headline/ConceptBox/Question 텍스트 존재, 진행 바 높이 3pt 유지 | AC#18 |
| TU-LS22 | `test_backButton_pops_toLearnList` | Back 버튼 탭 → `SajuLearnListView` 복귀 | AC#1 (진입점 pop) |
| TU-LS23 | `test_voiceOver_progressBar_label` | `SajuLessonProgressBar.label` contains "진행률" and percent string | AC#16 (VO) |
| TU-LS24 | `test_voiceOver_diagramPlaceholder_label` | `SajuLessonDiagramPlaceholder.label` contains "다이어그램 자리" | AC#16 (VO) |

> **Note — VoiceOver focus order (AC#16)**: Automated XCUITest cannot reliably verify the sequential focus traversal order. The correct view hierarchy order (NavBar → 진행 바 → sectionLabel → … → CTA) is enforced by the vstack/layout structure in Steps 4-7 and verified by manual VoiceOver testing as a release gate.

---

## 7. Risks / Open Questions

1. **`SajuLessonProviding` 프로토콜 파괴적 변경** — 기존 `lessonTitle(forId:)` 시그니처를 사용하는 `SajuTabDependenciesTests`의 `StubSajuLessonProvider`가 컴파일 실패한다. Step 1에서 함께 수정 필요.

2. **`sajuRouteDestination` 시그니처 변경** — `onReplaceTop` 파라미터 추가 시 모든 호출 지점(`SajuTabView`)을 동시에 수정해야 컴파일 통과. 한 스텝에서 묶어서 처리한다.

3. **Replace-top 네비게이션** — `SajuTabView.navigationPath`에 대한 직접 접근이 필요하므로 클로저 캡처로 전달한다. Path가 비어있을 때 `removeLast()` 크래시 방지를 위해 `if !navigationPath.isEmpty` 가드 필수.

4. **Fallback lesson의 퀴즈 처리** — 퀴즈 영역을 완전히 숨길지(`isFallback` 플래그), 아니면 비활성 처리할지는 spec이 "퀴즈 영역은 비활성/숨김 처리"로 열어두었다. 구현 시 숨김(opacity 0 또는 conditional rendering) 방식을 채택하고, `isFallback == true` 시 CTA도 비활성화로 처리.

5. **진행 바 위치** — spec은 "헤더 직하단"이라고 하지만 SwiftUI NavigationStack에서 `toolbar` 아래에 Custom progress bar를 두려면 `safeAreaInset(edge: .top)` 또는 ScrollView 상단에 고정 배치해야 한다. NavigationBar 아래 ScrollView 최상단에 고정 배치(`.ignoresSafeArea` 없이)하는 방식이 가장 단순하며, AC#5 clamp 동작에는 영향 없다.

6. **VoiceOver 포커스 순서(AC#16)** — SwiftUI에서 커스텀 VoiceOver 탐색 순서를 보장하려면 `accessibilitySortPriority` 또는 컨테이너 순서를 엄격히 유지해야 한다. UI 테스트로 자동 검증이 어려우므로 수동 검증 항목으로 남기되, 올바른 뷰 계층 순서로 구현한다.

7. **UITest push 버튼 ID** — 기존 `SajuNavPush_lessonL001`은 `"L-001"`을 push한다. WF4-07 기본값은 `"L-OH-003"`이므로 `SajuNavPush_lessonLOH003` 신규 추가. 기존 버튼은 유지해 하위 호환성 보장.

8. **퀴즈 정답/오답 accessibility trait** — SwiftUI는 임의 커스텀 `UIAccessibilityTraits`를 지원하지 않는다. 대신 각 `ChoiceOptionView`에 `.accessibilityValue(choiceA11yValue(...))` 를 적용해 VoiceOver가 "정답" 또는 "오답" 문자열을 읽도록 한다. 선택 전에는 빈 문자열. `static func choiceA11yValue(index: Int, selected: Int?, correct: Int) -> String` 순수 헬퍼로 추출하여 TL07-32에서 단위 검증한다. **해결됨**.
