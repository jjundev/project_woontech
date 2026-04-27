# implement-plan.md — WF4-03 사주 탭 Below-the-Fold (v1)

---

## 1. Goal

WF4-02의 above-fold(원국 카드 + 5 카테고리) 바로 아래에 **사주 공부하기 섹션**
(섹션 헤더 + 오늘의 한 가지 카드 + 학습 경로 4-그리드 + 용어 사전 카드 + Disclaimer)을
추가해 사주 탭 홈을 단일 스크롤 화면으로 완성한다.

---

## 2. Affected Files

### 2a. Modified

| 파일 경로 | 변경 내용 |
|---|---|
| `Woontech/Features/Saju/Providers/SajuLearningPathProviding.swift` | `FeaturedLesson`, `CoursePath` 모델 추가; 프로토콜에 `streakDays`, `featuredLesson`, `coursePaths`, `glossaryTermCount` 프로퍼티 추가(기존 `weeklyProgress`/`courses`는 유지); `MockSajuLearningPathProvider` mock 기본값 완성 |
| `Woontech/Features/Saju/SajuTabContentView.swift` | `learningPathProvider: any SajuLearningPathProviding` 파라미터 추가; `Spacer(minLength: 32)` → `SajuStudySectionView`로 교체(18pt 상단 마진) |
| `Woontech/Features/Saju/SajuTabView.swift` | `SajuTabContentView` 초기화 시 `deps.learningPath` 전달 |

### 2b. New

| 파일 경로 | 설명 |
|---|---|
| `Woontech/Features/Saju/BelowFold/SajuStudySectionView.swift` | Block A~E를 조립하는 최상위 컨테이너 |
| `Woontech/Features/Saju/BelowFold/SajuStudySectionHeaderView.swift` | Block A — 헤더 + 연속 배지 + "전체 ›" 링크 |
| `Woontech/Features/Saju/BelowFold/SajuFeaturedLessonCardView.swift` | Block B — 오늘의 한 가지 카드 |
| `Woontech/Features/Saju/BelowFold/SajuCourseGridView.swift` | Block C — 2×2 학습 경로 그리드 |
| `Woontech/Features/Saju/BelowFold/SajuCourseCardView.swift` | Block C — 개별 코스 카드 (진행률 바 포함) |
| `Woontech/Features/Saju/BelowFold/SajuGlossaryCardView.swift` | Block D — 용어 사전 카드 |
| `WoontechTests/Saju/SajuBelowFoldTests.swift` | 유닛 테스트 |
| `WoontechUITests/Saju/SajuBelowFoldUITests.swift` | UI 테스트 |

---

## 3. Data Model / State Changes

### 3a. 새 모델 타입 (`SajuLearningPathProviding.swift`에 추가)

```swift
/// Block B 오늘의 한 가지 카드에 바인딩되는 추천 레슨.
struct FeaturedLesson: Hashable {
    let id: String           // e.g. "L-TEN-001"
    let title: String        // e.g. "십성이란 무엇인가?"
    let durationLabel: String // e.g. "3분"
    let levelLabel: String    // e.g. "초급"
}

/// Block C 학습 경로 그리드의 한 코스 슬롯.
struct CoursePath: Hashable {
    let name: String         // e.g. "입문"
    let lessonCount: Int     // e.g. 7
    let averageMinutes: Int? // 옵셔널
    let progress: Double     // 0.0 ~ 1.0, 클램프 필요
}
```

### 3b. 프로토콜 확장 (`SajuLearningPathProviding`)

기존 `weeklyProgress`, `courses` 유지(기존 테스트 T10~T12 보호).
아래 4개 프로퍼티 **추가**:

```swift
protocol SajuLearningPathProviding {
    // 기존
    var weeklyProgress: WeeklyProgress { get }
    var courses: [SajuCourse] { get }
    // 신규
    var streakDays: Int { get }
    var featuredLesson: FeaturedLesson? { get }
    var coursePaths: [CoursePath] { get }
    var glossaryTermCount: Int { get }
}
```

기존 `MockSajuLearningPathProvider`에 대한 **default protocol extension** 제공:
- `streakDays` → `weeklyProgress.streakDays` 위임
- `coursePaths` → `courses` 배열에서 `CoursePath` 매핑

이렇게 하면 기존 `MockSajuLearningPathProvider` 및 외부 채택자의 컴파일을
유지하면서 신규 인터페이스를 추가할 수 있다.

### 3c. Mock 기본값 (`MockSajuLearningPathProvider`)

- `streakDays = 3` (weeklyProgress.streakDays에서 자동 충족)
- `featuredLesson = FeaturedLesson(id: "L-TEN-001", title: "십성이란 무엇인가?", durationLabel: "3분", levelLabel: "초급")`
- `coursePaths` → `courses` 매핑으로 기본 충족: `[(입문, 7, nil, 1.0), (오행, 5, nil, 0.6), (십성, 8, nil, 0.3), (대운, 6, nil, 0.0)]`
- `glossaryTermCount = 120`

### 3d. View 상태

모든 View는 `let` 프로퍼티(데이터 주입)만 사용하며 별도 `@State`/`@ObservedObject` 없음.
네비게이션은 `onNavigate: (SajuRoute) -> Void` 콜백으로 부모(`SajuTabView`)의
`navigationPath`에 append한다.

---

## 4. Implementation Steps

> 각 단계는 독립 컴파일·테스트 가능한 크기로 유지한다.

### Step 1 — 모델 + 프로토콜 확장
**파일:** `SajuLearningPathProviding.swift`

1. `FeaturedLesson` struct 추가.
2. `CoursePath` struct 추가.
3. `SajuLearningPathProviding` 프로토콜에 4개 프로퍼티 추가.
4. 프로토콜 extension에 default 구현:
   - `streakDays`: `weeklyProgress.streakDays`
   - `coursePaths`: `courses.map { CoursePath(name: $0.title, lessonCount: $0.lessonCount, averageMinutes: nil, progress: $0.progress) }`
5. `MockSajuLearningPathProvider`에 `featuredLesson`, `glossaryTermCount` 저장 프로퍼티 추가 및 default 초기화값 지정.
6. 빌드 확인 → 기존 T10~T12 테스트 통과 확인.

---

### Step 2 — Block A: `SajuStudySectionHeaderView`
**파일:** `BelowFold/SajuStudySectionHeaderView.swift`

- `streakDays: Int`, `onAllTap: () -> Void` 파라미터.
- HStack 레이아웃:
  - 좌측: "사주 공부하기" `Text` (bold 12pt, `ink`)
  - 스트릭 배지: `streakDays > 0`일 때만 `"🔥 연속 \(streakDays)일"` pill (배경 `gray`, 테두리 `line3`, cornerRadius 충분히).
  - `Spacer()`
  - 우측: "전체 ›" `Button` (muted) → `onAllTap()`.
- VoiceOver: 배지에 `.accessibilityLabel("연속 학습 \(streakDays)일")`.
- Identifier: 헤더 `"SajuStudySectionHeader"`, 배지 `"SajuStreakBadge"`, 버튼 `"SajuStudyAllButton"`.

---

### Step 3 — Block B: `SajuFeaturedLessonCardView`
**파일:** `BelowFold/SajuFeaturedLessonCardView.swift`

- `lesson: FeaturedLesson`, `onTap: () -> Void` 파라미터.
- HStack:
  - 좌측: `RoundedRectangle(cornerRadius: 8).fill(gray)` 50×50 placeholder.
  - 우측 VStack(alignment: .leading):
    - `"오늘의 한 가지"` (muted, 10pt)
    - `lesson.title` (bold 12pt, ink)
    - `"\(lesson.durationLabel) · \(lesson.levelLabel)"` (muted, 9pt)
- 전체를 `Button(action: onTap)` 로 감싸 hit target ≥44pt 보장 (`.frame(minHeight: 44)`).
- `accessibilityElement(children: .ignore)`, `.accessibilityLabel("오늘의 한 가지, \(lesson.title), \(lesson.durationLabel), \(lesson.levelLabel)")`.
- Identifiers: `"SajuFeaturedLessonCard"`.

---

### Step 4 — Block C 파트1: `SajuCourseCardView`
**파일:** `BelowFold/SajuCourseCardView.swift`

- `coursePath: CoursePath?`, `slotName: String`, `onTap: () -> Void` 파라미터.
  - `coursePath == nil` (4개 미만 시 빈 슬롯) → `locked` 상태: 흐린 배경(`gray2`), 진행률 0.
- Card VStack:
  - `Text(coursePath?.name ?? slotName)` (bold 12pt).
  - `Text("\(coursePath?.lessonCount ?? 0)강")` (muted 9pt) — locked이면 "-강".
  - 진행률 바: `GeometryReader` 사용, 전체 배경 `gray`, 채움 `ink` 또는 accent, 높이 3pt.
    - 채움 너비 = `max(0, min(1, coursePath?.progress ?? 0)) * totalWidth`.
- 전체 `Button(action: onTap)`. `.frame(minHeight: 44)`.
- VoiceOver: `.accessibilityLabel("\(name) 코스, \(lessonCount)강, 진행률 \(Int((progress*100).rounded()))%")`.
- Identifiers: `"SajuCourseCard_\(slotName)"`.

---

### Step 5 — Block C 파트2: `SajuCourseGridView`
**파일:** `BelowFold/SajuCourseGridView.swift`

- `coursePaths: [CoursePath]`, `onTap: () -> Void` 파라미터.
- 고정 슬롯 순서: `let fixedOrder = ["입문", "오행", "십성", "대운"]`.
- 각 슬롯별 `coursePaths.first(where: { $0.name == name })` 으로 매칭 — 없으면 nil.
- `LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8)` 사용.
- 각 슬롯 → `SajuCourseCardView(coursePath: match, slotName: name, onTap: { onTap() })`.
- Identifier: `"SajuCourseGrid"`.

---

### Step 6 — Block D: `SajuGlossaryCardView`
**파일:** `BelowFold/SajuGlossaryCardView.swift`

- `glossaryTermCount: Int` 파라미터.
- HStack:
  - 32×32 placeholder RoundedRectangle (배경 `gray`) 안에 `Text("A")`.
  - VStack(leading): `"용어 사전"` (bold 12pt) + subtitle.
    - `glossaryTermCount > 0` → `"명리학 용어 \(glossaryTermCount)개"`, else `"명리학 용어"`.
  - Spacer()
  - `Text("›")` (muted).
- `Button(action: { /* no-op */ })` 전체 감쌈, `.frame(minHeight: 44)`.
- `.accessibilityLabel("용어 사전, 명리학 용어 \(glossaryTermCount)개")`.
- `.accessibilityHint("준비중")`.
- Identifier: `"SajuGlossaryCard"`.

---

### Step 7 — Block E 재사용 & 조립: `SajuStudySectionView`
**파일:** `BelowFold/SajuStudySectionView.swift`

- 파라미터: `provider: any SajuLearningPathProviding`, `onNavigate: (SajuRoute) -> Void`.
- 본문 VStack(alignment: .leading, spacing: 12):
  1. `SajuStudySectionHeaderView(streakDays: provider.streakDays, onAllTap: { onNavigate(.learn) })`.
  2. `if let lesson = provider.featuredLesson { SajuFeaturedLessonCardView(...) }`.
  3. `SajuCourseGridView(coursePaths: provider.coursePaths, onTap: { onNavigate(.learn) })`.
  4. `SajuGlossaryCardView(glossaryTermCount: provider.glossaryTermCount)`.
  5. `DisclaimerView()` (기존 `Home/DisclaimerView.swift` 그대로 재사용).
- `.padding(.horizontal, 16)`.
- Identifier: `"SajuStudySection"`.

---

### Step 8 — `SajuTabContentView` 수정
**파일:** `SajuTabContentView.swift`

- `learningPathProvider: any SajuLearningPathProviding` 파라미터 추가.
- `Spacer(minLength: 32)` 제거 → `SajuStudySectionView(provider: learningPathProvider, onNavigate: onNavigate)` 추가.
- `.padding(.top, 18)` 을 `SajuStudySectionView` 에 적용 (VStack spacing 대신 별도 modifier로 섹션 마진 명시).

---

### Step 9 — `SajuTabView` 수정
**파일:** `SajuTabView.swift`

- `SajuTabContentView(...)` 초기화에 `learningPathProvider: deps.learningPath` 전달.
- 빌드 확인.

---

### Step 10 — 유닛 테스트 작성
**파일:** `WoontechTests/Saju/SajuBelowFoldTests.swift`
(상세는 섹션 5 참조)

---

### Step 11 — UI 테스트 작성
**파일:** `WoontechUITests/Saju/SajuBelowFoldUITests.swift`
(상세는 섹션 6 참조)

---

## 5. Unit Test Plan

파일: `WoontechTests/Saju/SajuBelowFoldTests.swift`

| ID | 테스트명 | 검증 대상 (AC) |
|---|---|---|
| TB-01 | `test_mockProvider_streakDays_is3` | `MockSajuLearningPathProvider().streakDays == 3` | AC2 |
| TB-02 | `test_mockProvider_featuredLesson_notNil` | `featuredLesson != nil` | AC4 |
| TB-03 | `test_mockProvider_featuredLesson_title_십성이란무엇인가` | `featuredLesson!.title == "십성이란 무엇인가?"` | AC4 |
| TB-04 | `test_mockProvider_featuredLesson_duration_3분_level_초급` | durationLabel, levelLabel | AC4 |
| TB-05 | `test_mockProvider_featuredLesson_id_LTEN001` | `featuredLesson!.id == "L-TEN-001"` | AC5 |
| TB-06 | `test_mockProvider_coursePaths_count_is4` | `coursePaths.count == 4` | AC7 |
| TB-07 | `test_mockProvider_coursePaths_names_fixed` | names == ["입문","오행","십성","대운"] (순서 포함) | AC7 |
| TB-08 | `test_mockProvider_coursePaths_progress_inRange` | 모든 `progress` ∈ [0.0, 1.0] | AC8 |
| TB-09 | `test_mockProvider_glossaryTermCount_is120` | `glossaryTermCount == 120` | AC10 |
| TB-10 | `test_courseGrid_fixedOrder_입문오행십성대운` | `SajuCourseGridView`의 내부 `fixedOrder` 배열 검증 | AC7 |
| TB-11 | `test_courseGrid_missingCourse_usesLockSlot` | provider.coursePaths=[] 주입 시 4슬롯 모두 nil(locked) | AC7 |
| TB-12 | `test_progressBar_clamp_above1` | progress=1.5 → clamp=1.0 | AC8 |
| TB-13 | `test_progressBar_clamp_below0` | progress=-0.5 → clamp=0.0 | AC8 |
| TB-14 | `test_studyHeader_streakBadge_hidden_when0` | streakDays=0 → badge 노출 안 됨 (조건 분기 검증) | AC2 |
| TB-15 | `test_studyHeader_streakBadge_shown_when3` | streakDays=3 → badge 표시 | AC2 |
| TB-16 | `test_studyHeader_allTap_fires_learnRoute` | `onAllTap` 콜백 캡처 → SajuRoute.learn | AC3 |
| TB-17 | `test_featuredLessonCard_tap_fires_lessonRoute_LTEN001` | onTap 콜백 → SajuRoute.lesson(id: "L-TEN-001") | AC5 |
| TB-18 | `test_glossaryCard_subtitle_120개` | `glossaryTermCount=120` → subtitle "명리학 용어 120개" | AC10 |
| TB-19 | `test_glossaryCard_subtitle_count0_no개suffix` | `glossaryTermCount=0` → "명리학 용어" | AC10 |
| TB-20 | `test_disclaimer_text_contains_학습참고용` | `DisclaimerView` body text에 "본 앱은 학습·참고용이며 투자 권유가 아닙니다." 포함 | AC12 |
| TB-21 | `test_studySection_featuredLessonNil_cardAbsent` | featuredLesson=nil 주입 → SajuFeaturedLessonCardView 렌더 안됨 (VStack 내 조건 분기) | AC6 |
| TB-22 | `test_voiceOver_featuredLessonCard_accessibilityLabel` | `accessibilityLabel` == "오늘의 한 가지, 십성이란 무엇인가?, 3분, 초급" | AC15 |
| TB-23 | `test_voiceOver_courseCard_accessibilityLabel` | 입문 카드 → "입문 코스, 7강, 진행률 100%" | AC (non-func) |
| TB-24 | `test_voiceOver_glossaryCard_accessibilityHint_준비중` | `.accessibilityHint == "준비중"` | AC11 |
| TB-25 | `test_glossaryCard_tap_doesNotFireNavigate` | onTap 콜백 없음(no-op) 확인 | AC11 |

---

## 6. UI Test Plan

파일: `WoontechUITests/Saju/SajuBelowFoldUITests.swift`

모든 테스트는 `-resetOnboarding -openSajuTab` 으로 앱을 실행하고
`app.otherElements["SajuTabRoot"]` 존재 확인 후 스크롤로 below-fold 진입.

| ID | 테스트명 | 검증 방법 | AC |
|---|---|---|---|
| TU-B01 | `test_studySection_exists_belowAboveFold` | 스크롤 후 `"SajuStudySection"` 존재 & 원국/카테고리 카드도 여전히 존재 | AC1 |
| TU-B02 | `test_streakBadge_visibleWhenDefault` | `"SajuStreakBadge"` 존재, label에 "🔥 연속 3일" 포함 | AC2 |
| TU-B03 | `test_streakBadge_hidden_when_streakDays0` | `-sajuStreakDays 0` 런치 env 주입 시 `"SajuStreakBadge"` 미존재 | AC2 |
| TU-B04 | `test_allButton_tap_pushesLearnRoute` | `"SajuStudyAllButton"` 탭 → `"SajuPlaceholderDestination_learn"` 노출 | AC3 |
| TU-B05 | `test_featuredLessonCard_exists_withDefaultMock` | `"SajuFeaturedLessonCard"` 존재, label에 "십성이란 무엇인가?" 포함 | AC4 |
| TU-B06 | `test_featuredLessonCard_label_contains_3분_초급` | card.label에 "3분", "초급" 포함 | AC4 |
| TU-B07 | `test_featuredLessonCard_tap_pushesLesson_LTEN001` | 탭 → `"SajuPlaceholderDestination_lesson"` + Identifier label "L-TEN-001" | AC5 |
| TU-B08 | `test_featuredLessonCard_absent_whenLessonNil` | `-sajuFeaturedLessonNil 1` env → `"SajuFeaturedLessonCard"` 미존재 & 그리드가 헤더 바로 아래 위치 | AC6 |
| TU-B09 | `test_courseGrid_fourCardsExist` | `"SajuCourseCard_입문"` 등 4개 버튼 존재 | AC7 |
| TU-B10 | `test_courseGrid_order_fixed` | cards 순서: 입문 frame.minY ≤ 오행 ≤ 십성 ≤ 대운 (좌→우, 상→하) | AC7 |
| TU-B11 | `test_courseCard_introProgress_100percent` | `"SajuCourseCard_입문"` label에 "100%" 포함 | AC8 |
| TU-B12 | `test_courseCard_daewoonProgress_0percent` | `"SajuCourseCard_대운"` label에 "0%" 포함 | AC8 |
| TU-B13 | `test_courseCard_tap_pushesLearn` | `"SajuCourseCard_입문"` 탭 → `"SajuPlaceholderDestination_learn"` | AC9 |
| TU-B14 | `test_glossaryCard_subtitle_120개` | `"SajuGlossaryCard"` 존재, label에 "명리학 용어 120개" | AC10 |
| TU-B15 | `test_glossaryCard_tap_noNavigation` | 탭 후 path 변화 없음 (SajuStudySection 여전히 최상위) | AC11 |
| TU-B16 | `test_disclaimer_text_visible` | `"DisclaimerText"` 존재 & label에 "본 앱은 학습·참고용이며" 포함 | AC12 |
| TU-B17 | `test_tabBar_active_index2` | `app.tabBars.buttons["사주 탭"].isSelected == true` | AC13 |
| TU-B18 | `test_dynamicType_xl_gridCards_noTruncation` | XL DT env 주입 → 카드 height > 44 & 4개 모두 존재 | AC14 |
| TU-B19 | `test_voiceOver_featuredLessonCard_accessibilityLabel` | card.label == "오늘의 한 가지, 십성이란 무엇인가?, 3분, 초급" | AC15 |
| TU-B20 | `test_hitTarget_allCards_minHeight44` | FeaturedLesson, 4 course cards, Glossary card .frame.height ≥ 44 | AC16 |
| TU-B21 | `test_hitTarget_allCards_minWidth44` | 동일 카드 .frame.width ≥ 44 | AC16 |

> **런치 인수 약속** (TU-B03, TU-B08에서 필요):
> - `-sajuStreakDays 0`: `MockSajuLearningPathProvider`의 streakDays를 0으로 오버라이드.
> - `-sajuFeaturedLessonNil 1`: `featuredLesson = nil`로 오버라이드.
>
> 이 인수들은 `SajuTabDependencies` 또는 `WoontechApp` 초기화 시 `ProcessInfo.processInfo.arguments` 를 읽어 mock 주입값을 조정하는 형태로 구현한다.

---

## 7. Risks / Open Questions

1. **런치 인수 기반 mock 오버라이드 패턴**: TU-B03/TU-B08은 `streakDays=0` 및 `featuredLesson=nil` mock을 앱 레이어에서 주입해야 한다. 기존 코드베이스에 이 패턴의 선례(`-resetOnboarding`, `-openSajuTab`)가 있으므로 동일 방식으로 `WoontechApp` 진입 시 `ProcessInfo` 인수를 읽어 `SajuTabDependencies` mock을 조정하는 코드를 추가해야 한다. 패턴 정합성 확인 필요.

2. **프로토콜 default 구현 충돌**: `streakDays`의 default 구현이 `weeklyProgress.streakDays`를 위임하면 기존 T10~T12 유닛 테스트는 건드리지 않고 통과할 수 있다. 단, `coursePaths`의 default 구현은 `SajuCourse → CoursePath` 매핑 시 `averageMinutes`가 없으므로 nil로 채워진다. 스펙에서 `averageMinutes`는 옵셔널이므로 문제없다.

3. **`DisclaimerView` 재사용 경로**: `Home/DisclaimerView.swift`는 현재 `Features/Home/` 아래에 있다. 사주 탭에서 직접 import하는 것은 모듈 구조상 허용되지만, 향후 공통 Shared 폴더로 이동이 권장된다. 현 슬라이스에서는 이동 없이 직접 참조한다.

4. **2×2 그리드 레이아웃 구현**: `LazyVGrid` 사용 시 카드 높이 균등화를 위해 `.aspectRatio` 또는 `alignmentGuide` 가 필요할 수 있다. Dynamic Type XL에서 타이틀이 wrap되면 카드 높이가 달라질 수 있으며, 진행률 바가 잘리지 않도록 `fixedSize(horizontal: false, vertical: true)` 적용을 검토해야 한다.

5. **TabBar active=2 검증(AC13)**: `SajuTabView`의 TabBar는 `MainTabContainerView`가 제어한다. `-openSajuTab` 런치 인수 시 이미 active=2로 진입하므로 TU-B17은 단순 존재 확인으로 충분하나, selected 상태를 XCTest에서 `isSelected` 프로퍼티로 직접 읽는 것이 iOS 버전에 따라 불안정할 수 있다. 대안으로 `app.tabBars.buttons["사주 탭"].label` 검증으로 대체 가능.

6. **`SajuCourseGridView`의 진행률 바 너비**: `GeometryReader`를 사용한 너비 비율 계산은 SwiftUI layout pass 타이밍에 따라 0으로 초기 렌더될 수 있다. `PreferenceKey` 기반 또는 `overlay` 방식으로 안정적으로 구현할 것을 권장한다.
