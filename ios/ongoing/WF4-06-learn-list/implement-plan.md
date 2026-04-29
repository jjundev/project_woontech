# implement-plan.md — WF4-06 사주 공부 리스트 (v2)

---

## 1. Goal

`SajuRoute.learn`의 목적지를 "준비중" placeholder에서 실제 **`SajuLearnListView`**로 교체한다.  
카테고리 필터 pill, 주간 진행 배너, 듀오링고식 코스 셀(4-상태), 추천 아티클 카드를 포함한 스크롤 가능 학습 목록 화면을 구현하고, locked 셀 탭 시 2초 자동 닫힘 토스트를 제공한다.

---

## 2. Affected Files

### 수정 (Modified)

| 파일 | 변경 내용 |
|------|-----------|
| `Woontech/Features/Saju/Providers/SajuLearningPathProviding.swift` | 새 모델 타입 추가, 프로토콜 요건 3개 추가, `WeeklyProgress`에 `ratio` computed property 추가, `MockSajuLearningPathProvider` 기본값 확장 |
| `Woontech/Features/Saju/SajuRouteDestinations.swift` | `.learn` 케이스를 `SajuPlaceholderDestinationView` → `SajuLearnListView`로 교체 |
| `Woontech/App/WoontechApp.swift` | UI 테스트용 launch-arg 파싱 추가 (`-sajuLearnArticlesEmpty`) |
| `WoontechUITests/Saju/SajuTabFoundationUITests.swift` | T20 테스트: `SajuPlaceholderDestination_learn` assertion을 `SajuLearnListView` 식별자로 교체 |

### 신규 (New)

| 파일 | 역할 |
|------|------|
| `Woontech/Features/Saju/Learn/SajuLearnListView.swift` | 메인 화면 컨테이너 (NavBar 툴바, ScrollView, 토스트 overlay) |
| `Woontech/Features/Saju/Learn/SajuLearnCategoryPillsView.swift` | 가로 스크롤 pill 스트립 |
| `Woontech/Features/Saju/Learn/SajuWeeklyProgressBannerView.swift` | 주간 진행 배너 카드 |
| `Woontech/Features/Saju/Learn/SajuLessonRowCardView.swift` | 코스 레슨 셀 (4-상태 인디케이터) |
| `Woontech/Features/Saju/Learn/SajuLearnArticleCardView.swift` | 추천 아티클 카드 |
| `WoontechTests/Saju/SajuLearnListTests.swift` | Unit tests |
| `WoontechUITests/Saju/SajuLearnListUITests.swift` | UI tests |

---

## 3. Data Model / State Changes

### 3-a. `WeeklyProgress` 보강 (기존 struct 확장)

기존 필드: `completed: Int`, `goal: Int`, `streakDays: Int`  
추가: computed property `var ratio: Double { goal > 0 ? Double(completed) / Double(goal) : 0.0 }`  
(spec의 `completedCount` = `completed`, `totalCount` = `goal`으로 매핑.)

### 3-b. 신규 모델 타입 (`SajuLearningPathProviding.swift`에 추가)

```swift
struct LearnCategory: Hashable, Identifiable {
    let id: String          // e.g. "all"
    let label: String       // e.g. "전체"
}

enum LessonStatus: String, Hashable, CaseIterable {
    case completed, current, pending, locked
}

struct LessonRow: Hashable, Identifiable {
    let id: String
    let number: Int
    let title: String
    let durationLabel: String
    let status: LessonStatus
}

struct CourseSection: Hashable {
    let name: String
    let lessonCount: Int
    let averageMinutes: Int
    let lessons: [LessonRow]
}

struct Article: Hashable, Identifiable {
    let id: String
    let title: String
    let metaLabel: String
}
```

### 3-c. `SajuLearningPathProviding` 프로토콜 요건 추가

```swift
var learnCategories: [LearnCategory] { get }       // 길이 6 고정
var introductoryCourse: CourseSection { get }
var recommendedArticles: [Article] { get }          // 길이 0~N
```

기존 채택자 코드를 깨지 않도록 protocol extension에 default 구현 제공:
- `learnCategories`: 6개 기본값 반환
- `introductoryCourse`: 빈 7-레슨 stub 반환
- `recommendedArticles`: `[]` 반환

### 3-d. `MockSajuLearningPathProvider` 기본값 추가

- `learnCategories` = `[전체, 입문, 오행, 십성, 대운, 합충]` (id: "all","intro","elements","tenGods","daewoon","hapchung")
- `introductoryCourse` = 7-레슨 기본값 (spec §Functional requirements 그대로)
- `recommendedArticles` = 2건 (spec §Functional requirements 그대로)

### 3-e. `SajuLearnListView` 로컬 상태

```swift
@State private var selectedCategoryId: String = "all"   // 첫 진입 시 "전체" 선택
@State private var toastVisible: Bool = false            // locked 카드 토스트
@State private var toastTask: Task<Void, Never>? = nil  // 2초 자동 닫힘 Task
```

---

## 4. Implementation Steps

각 단계는 빌드·단위 테스트 가능 수준으로 분리한다.

### Step 1 — 모델 타입 추가 (`SajuLearningPathProviding.swift`)

1. `WeeklyProgress`에 `ratio` computed property 추가.
2. `LessonStatus`, `LessonRow`, `CourseSection`, `LearnCategory`, `Article` 타입을 동일 파일 상단에 추가.
3. `SajuLearningPathProviding` 프로토콜에 `learnCategories`, `introductoryCourse`, `recommendedArticles` 요건 추가.
4. Protocol extension에 default 구현 3개 추가 (기존 채택자 컴파일 보호).
5. `MockSajuLearningPathProvider`에 새 프로퍼티 저장 필드 및 `init` 기본값 추가.  
   - `introductoryCourse` 기본값: 7개 `LessonRow` (spec 그대로, id = "L1"~"L7", status = completed/completed/completed/current/locked/locked/locked).
   - `recommendedArticles` 기본값: 2건 (title/metaLabel spec 그대로, id = "A1","A2").

**검증**: `MockSajuLearningPathProvider()` 인스턴스 생성 후 `.learnCategories.count == 6`, `.introductoryCourse.lessons.count == 7` 확인.

---

### Step 2 — `SajuLessonRowCardView` 구현

인디케이터 원(28×28pt), 중앙 텍스트 영역, 우측 아이콘을 포함하는 카드 뷰.

- **파라미터**: `lesson: LessonRow`, `onTap: () -> Void`
- **인디케이터**:
  - `.completed` → `Circle().fill(.black)` + `Image(systemName: "checkmark")` (흰색)
  - `.current`   → `Circle().fill(.white).stroke(Color.black, lineWidth: 2)` + `Text(number)` 검정
  - `.pending`   → `Circle().fill(.white).stroke(DesignTokens.line2, lineWidth: 1)` + `Text(number)` 검정
  - `.locked`    → `Circle().fill(.white).stroke(DesignTokens.line2, lineWidth: 1)` + `Text(number)` muted
- **가운데 영역**:
  - 타이틀: `Font.system(size: 12, weight: .bold)`. current는 `.ink`, 나머지 `.ink`(locked는 muted)
  - 메타: `durationLabel` + (current이면 ` · 이어보기`). 폰트 9pt muted.
- **우측 아이콘**: locked → `Image(systemName: "lock.fill")` muted; 그 외 → `Image(systemName: "chevron.right")` muted
- **탭 동작**:
  - locked 카드는 `Button` 대신 `.onTapGesture`로 처리하거나, `disabled(false)` Button에서 `onTap` 콜백을 로컬 guard로 분기.
  - 실제로는 `Button(action: onTap)`을 사용하되, 상위(`SajuLearnListView`)에서 locked 여부를 판단해 route 탐색 vs 토스트를 결정. 카드 자체는 항상 탭 가능.
- **Accessibility**:
  - label: `"\(number)강 \(title), \(durationLabel)\(status == .current ? ", 이어보기" : ""), 상태 \(statusKorean)"`
  - locked trait: `.accessibilityAddTraits(.notEnabled)` (잠김 신호)
- **hit target**: `.frame(minHeight: 44)` + `.contentShape(Rectangle())`

**정적 helper** `SajuLessonRowCardView.statusKorean(_ status: LessonStatus) -> String`을 노출해 단위 테스트에서 직접 호출 가능하도록 한다.

---

### Step 3 — `SajuLearnCategoryPillsView` 구현

- **파라미터**: `categories: [LearnCategory]`, `selectedId: Binding<String>`
- `ScrollView(.horizontal, showsIndicators: false)` 안에 `HStack(spacing: 6)`.
- **중요: 부모로부터 horizontal padding을 받지 않는다.** 대신 내부 `HStack`에 직접 `.padding(.leading, 16).padding(.trailing, 16)`을 적용하여 시각적 여백을 만든다. 이렇게 해야 `ScrollView`가 전체 화면 너비를 차지하면서도 pill content가 16pt 안쪽에서 시작한다. 부모 `SajuLearnListView`의 `.padding(.horizontal, 16)` 블록 밖에 배치해야 한다(아래 Step 6 body 구조 참조).
- Pill 스타일:
  - 선택 → `Capsule().fill(.black)` + `Text` white, bold
  - 미선택 → `Capsule().fill(.white).stroke(DesignTokens.line3)` + `Text` `.ink`
- 탭 시 `selectedId.wrappedValue = category.id`
- Accessibility: `accessibilityLabel("\(label), \(isSelected ? "선택됨" : "선택 안됨")")`

---

### Step 4 — `SajuWeeklyProgressBannerView` 구현

- **파라미터**: `progress: WeeklyProgress`
- 외형: RoundedRectangle 카드(모서리 10pt, stroke line3), 내부 padding 12pt.
- 좌측 섹션:
  - "이번 주 학습" muted 9pt
  - `streakDays > 0` 이면 `"🔥 연속 {streakDays}일"` 뱃지 (pill 스타일, 9pt bold)
  - `"{completed} / {goal}강 완료"` bold 14pt
- 우측 섹션: placeholder `RoundedRectangle(cornerRadius: 6).fill(DesignTokens.gray)` 44×44pt (% 라벨 포함).
- 하단 진행률 바:
  - 높이 4pt, `max(0, min(1, progress.ratio))` × 전체 너비
  - GeometryReader 방식 (기존 `SajuCourseCardView` 패턴과 동일)
- Accessibility: `.accessibilityElement(children: .ignore)` + `.accessibilityLabel("이번 주 학습 진행, \(completed)강 완료 중 \(goal)강, 연속 \(streakDays)일")`
- `SajuWeeklyProgressBannerView.clampedRatio(_ raw: Double) -> Double` static helper 노출.

---

### Step 5 — `SajuLearnArticleCardView` 구현

- **파라미터**: `article: Article`, `onTap: () -> Void`
- 좌측: placeholder 44×44pt `RoundedRectangle` gray
- 우측: title bold 11pt + metaLabel muted 9pt
- 탭: no-op (`onTap` 전달하지만 상위에서 no-op 제공)
- Accessibility hint: `"준비중"`
- hit target: `.frame(minHeight: 44)`

---

### Step 6 — `SajuLearnListView` 구현

```swift
struct SajuLearnListView: View {
    let provider: any SajuLearningPathProviding
    let onNavigate: (SajuRoute) -> Void
    @State private var selectedCategoryId: String = "all"
    @State private var toastVisible: Bool = false
    @State private var toastTask: Task<Void, Never>? = nil
```

**NavBar** (iOS 17+ toolbar API):
```swift
.navigationTitle("사주 공부")
.navigationBarTitleDisplayMode(.inline)
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Text("검색")
            .font(.system(size: 14))
            .foregroundStyle(DesignTokens.muted)
            .onTapGesture { /* no-op */ }
            .accessibilityHint("준비중")
            .accessibilityIdentifier("SajuLearnSearchButton")
    }
}
```

**Body 구조**:

> ⚠️ **레이아웃 주의**: pill strip은 전체 너비(full-width)를 차지해야 하므로 `.padding(.horizontal, 16)` 블록 *바깥*에 독립적으로 배치한다. 나머지 콘텐츠(배너, 코스, 아티클)에만 `.padding(.horizontal, 16)`을 적용한다.

```
ZStack(alignment: .bottom) {
    ScrollView {
        VStack(alignment: .leading, spacing: 0) {
            // 1. 카테고리 pill 가로 스크롤 — full-width, 내부 HStack에서 16pt 패딩 처리
            SajuLearnCategoryPillsView(
                categories: provider.learnCategories,
                selectedId: $selectedCategoryId
            )
            .padding(.top, 12)
            // ↑ SajuLearnCategoryPillsView는 자체 HStack에
            //   .padding(.leading, 16).padding(.trailing, 16) 을 적용함.
            //   여기서 별도 horizontal padding을 주지 않는다.

            // 2–5. 나머지 콘텐츠 — 16pt horizontal padding 적용
            VStack(alignment: .leading, spacing: 0) {
                // 2. 주간 진행 배너 카드
                SajuWeeklyProgressBannerView(progress: provider.weeklyProgress)
                    .padding(.top, 12)

                // 3. 코스 헤더
                CourseHeaderView(course: provider.introductoryCourse)
                    .padding(.top, 18)

                // 4. 코스 레슨 리스트
                VStack(spacing: 6) {
                    ForEach(provider.introductoryCourse.lessons) { lesson in
                        SajuLessonRowCardView(lesson: lesson) {
                            handleLessonTap(lesson)
                        }
                    }
                }
                .padding(.top, 8)

                // 5. 추천 아티클 섹션 (비어있으면 전체 숨김)
                if !provider.recommendedArticles.isEmpty {
                    ArticlesSectionView(
                        articles: provider.recommendedArticles
                    )
                    .padding(.top, 18)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    // 토스트 overlay
    if toastVisible {
        ToastBannerView(message: "이전 강의를 먼저 완료하세요")
            .padding(.bottom, 16)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}
.animation(.easeInOut(duration: 0.2), value: toastVisible)
.accessibilityIdentifier("SajuLearnListView")
```

**`handleLessonTap`**:
```swift
private func handleLessonTap(_ lesson: LessonRow) {
    switch lesson.status {
    case .completed, .current, .pending:
        onNavigate(.lesson(id: lesson.id))
    case .locked:
        showLockedToast()
    }
}

private func showLockedToast() {
    toastTask?.cancel()
    withAnimation { toastVisible = true }
    UIAccessibility.post(notification: .announcement,
                         argument: "이전 강의를 먼저 완료하세요")
    toastTask = Task {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        guard !Task.isCancelled else { return }
        await MainActor.run {
            withAnimation { toastVisible = false }
        }
    }
}
```

**`ToastBannerView`** (inline 또는 별도 파일):  
`RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.8))` + `Text` 흰색 14pt, 좌우 padding 16pt, 세로 12pt, `.safeAreaInset`/overlay로 safe-area 위에 위치.

**`CourseHeaderView`** (private ViewBuilder 또는 inner struct):
- 좌측: `"\(course.name) 코스"` bold 12pt
- 우측: muted `"\(course.lessonCount)강 · 평균 \(course.averageMinutes)분"` 10pt

**Accessibility identifier 정책**:
- `SajuLearnListView`: 최외곽 `ZStack`
- `SajuLearnCategoryPills`: pill strip container
- `SajuLearnCategoryPill_\(category.id)`: 각 pill 버튼
- `SajuLearnWeeklyBanner`: 진행 배너 카드
- `SajuLearnStreakBadge`: streak 배지
- `SajuLearnCourseHeader`: 헤더
- `SajuLearnLessonCard_\(lesson.id)`: 각 레슨 카드 (예: `SajuLearnLessonCard_L1`)
- `SajuLearnArticleSection`: 아티클 섹션
- `SajuLearnArticleCard_\(article.id)`: 각 아티클 카드
- `SajuLearnToast`: 토스트 배너

---

### Step 7 — `SajuRouteDestinations.swift` 업데이트

`.learn` case를 교체:
```swift
case .learn:
    SajuLearnListView(
        provider: deps.learningPath,
        onNavigate: onNavigate
    )
```

---

### Step 8 — `WoontechApp.swift` launch arg 추가

기존 `sajuDeps` 빌드 로직에 다음 arg 파싱을 **2개** 추가:

```swift
let sajuLearnArticlesEmpty = args.contains("-sajuLearnArticlesEmpty")
let sajuLearnStreakZero    = args.contains("-sajuLearnStreakZero")
```

`needsCustomLearningPath` 조건에 두 플래그를 모두 포함 (`sajuLearnArticlesEmpty || sajuLearnStreakZero`).

| 플래그 | 효과 |
|--------|------|
| `-sajuLearnArticlesEmpty` | `MockSajuLearningPathProvider`를 `recommendedArticles: []`로 초기화 |
| `-sajuLearnStreakZero` | `MockSajuLearningPathProvider`를 `weeklyProgress.streakDays = 0`으로 초기화 (completed=0, total=5, ratio=0.0) |

> UI 테스트 TU-L12(`test_weeklyBanner_streakBadge_hidden_streakDays0`)에서 `-sajuLearnStreakZero`를 launch argument로 사용한다.

---

### Step 9 — `SajuTabFoundationUITests` T20 업데이트

```swift
// T20 — WF4-06: .learn 라우트가 SajuLearnListView로 교체됨.
func test_sajuRoute_pushLearn_showsLearnListView() {
    launchSajuTab()
    let btn = app.buttons["SajuNavPush_learn"]
    XCTAssertTrue(btn.waitForExistence(timeout: 3))
    btn.tap()
    XCTAssertTrue(
        app.otherElements["SajuLearnListView"].waitForExistence(timeout: 5),
        "SajuLearnListView should appear after pushing .learn route"
    )
}
```

---

### Step 10 — Unit tests 작성 (`SajuLearnListTests.swift`)

(§5 참고)

### Step 11 — UI tests 작성 (`SajuLearnListUITests.swift`)

(§6 참고)

---

## 5. Unit Test Plan

파일: `WoontechTests/Saju/SajuLearnListTests.swift`

| ID | 테스트 메서드 | 검증 내용 | 관련 AC |
|----|-------------|-----------|--------|
| TL-01 | `test_mockProvider_learnCategories_count_is6` | `MockSajuLearningPathProvider().learnCategories.count == 6` | AC3 |
| TL-02 | `test_mockProvider_learnCategories_order_fixed` | 순서 `["전체","입문","오행","십성","대운","합충"]` | AC3 |
| TL-03 | `test_learnListView_initialSelectedCategoryId_isAll` | 초기 `selectedCategoryId == "all"` (뷰 생성 직후 상태 점검) | AC4 |
| TL-04 | `test_pill_selection_switchHighlights` | selectedId 바인딩 변경 시 이전 pill 미선택 | AC5 |
| TL-05 | `test_weeklyProgress_ratio_completedDivGoal` | `WeeklyProgress(completed:3,goal:5).ratio ≈ 0.6` | AC7 |
| TL-06 | `test_weeklyProgress_ratio_clamp_above1` | `ratio` when completed > goal → `clampedRatio(1.2) == 1.0` | AC7 |
| TL-07 | `test_weeklyProgress_ratio_clamp_below0` | `clampedRatio(-0.1) == 0.0` | AC7 |
| TL-08 | `test_weeklyProgress_ratio_goalZero_returns0` | `WeeklyProgress(completed:0,goal:0).ratio == 0.0` | AC7 |
| TL-09 | `test_weeklyBanner_streakBadge_hidden_when0` | `streakDays == 0 → badge 조건 false` | AC6 |
| TL-10 | `test_weeklyBanner_streakBadge_shown_when3` | `streakDays == 3 → badge 조건 true` | AC6 |
| TL-11 | `test_weeklyBanner_text_completed_total_binding` | `"3 / 5강 완료"` (mock 기본값) | AC6 |
| TL-12 | `test_courseHeader_name_binding` | `"입문 코스"` = `provider.introductoryCourse.name + " 코스"` | AC8 |
| TL-13 | `test_courseHeader_lessonCount_averageMinutes` | `"7강 · 평균 3분"` | AC8 |
| TL-14 | `test_courseList_count_matches_lessonCount` | `introductoryCourse.lessons.count == introductoryCourse.lessonCount == 7` | AC9 |
| TL-15 | `test_lessonRow_statusKorean_completed` | `statusKorean(.completed) == "완료"` | AC10 |
| TL-16 | `test_lessonRow_statusKorean_current` | `statusKorean(.current) == "현재"` | AC11 |
| TL-17 | `test_lessonRow_statusKorean_pending` | `statusKorean(.pending) == "미완료"` | AC12 |
| TL-18 | `test_lessonRow_statusKorean_locked` | `statusKorean(.locked) == "잠김"` | AC13 |
| TL-19 | `test_lessonRow_current_meta_includes_이어보기` | current 레슨의 metaLine에 ` · 이어보기` 포함 | AC11 |
| TL-20 | `test_lessonRow_pending_meta_no_이어보기` | pending 레슨의 metaLine에 ` · 이어보기` 미포함 | AC12 |
| TL-21 | `test_handleLessonTap_completed_firesRoute` | completed 탭 → `onNavigate(.lesson(id:))` 호출됨 | AC14 |
| TL-22 | `test_handleLessonTap_current_firesRoute` | current 탭 → `onNavigate(.lesson(id:))` 호출됨 | AC14 |
| TL-23 | `test_handleLessonTap_pending_firesRoute` | pending 탭 → `onNavigate(.lesson(id:))` 호출됨 | AC14 |
| TL-24 | `test_handleLessonTap_locked_doesNotFireRoute` | locked 탭 → `onNavigate` 미호출 | AC15 |
| TL-25 | `test_recommendedArticles_sectionHidden_whenEmpty` | `recommendedArticles == [] → section 숨김 조건 true` | AC16 |
| TL-26 | `test_recommendedArticles_count_matches_provider` | mock 2건 → 카드 2개 | AC16 |
| TL-27 | `test_articleCard_tap_noRouteChange` | 아티클 탭 → navigate 미호출 | AC17 |
| TL-28 | `test_mockProvider_introductoryCourse_lesson4_isCurrent` | lessons[3].status == .current | AC11 |
| TL-29 | `test_mockProvider_introductoryCourse_lesson5_isLocked` | lessons[4].status == .locked | AC13 |
| TL-30 | `test_weeklyProgressBannerView_clampedRatio_0_6` | `SajuWeeklyProgressBannerView.clampedRatio(0.6) ≈ 0.6` | AC7 |

---

## 6. UI Test Plan

파일: `WoontechUITests/Saju/SajuLearnListUITests.swift`

공통 설정: `app.launchArguments = ["-resetOnboarding", "-openSajuTab"]` + UI 테스트 navigation trigger `SajuNavPush_learn` 또는 below-fold 스크롤로 진입.

`launchLearnList()` helper: `-resetOnboarding -openSajuTab` launch → `SajuNavPush_learn` 버튼 탭 → `SajuLearnListView` waitForExistence.

| ID | 메서드 | 검증 내용 | 관련 AC |
|----|--------|-----------|--------|
| TU-L01 | `test_navigate_fromBelowFold_allButton` | 아래 스크롤 → "전체 ›" 탭 → `SajuLearnListView` push | AC1 |
| TU-L02 | `test_navigate_fromBelowFold_courseCard` | 아래 스크롤 → `SajuCourseCard_입문` 탭 → `SajuLearnListView` push | AC1 |
| TU-L03 | `test_navBar_title_사주공부` | `navigationTitle` 텍스트 == "사주 공부" | AC2 |
| TU-L04 | `test_navBar_searchButton_exists` | `SajuLearnSearchButton` exists | AC2 |
| TU-L05 | `test_navBar_searchButton_tap_isNoOp` | 탭 후 `SajuLearnListView` still exists (push 없음) | AC18 |
| TU-L06 | `test_categoryPills_count_is6` | `SajuLearnCategoryPill_*` × 6 | AC3 |
| TU-L07 | `test_categoryPills_order_fixed` | minX frame 순서 검증 (전체 < 입문 < ... < 합충) | AC3 |
| TU-L08 | `test_categoryPills_initialSelection_전체` | `SajuLearnCategoryPill_all` label contains "선택됨" (VoiceOver label) | AC4 |
| TU-L09 | `test_categoryPills_switchSelection` | 입문 탭 후 `SajuLearnCategoryPill_intro` 선택됨, `all` 미선택 | AC5 |
| TU-L10 | `test_weeklyBanner_exists` | `SajuLearnWeeklyBanner` exists | AC6 |
| TU-L11 | `test_weeklyBanner_streakBadge_visible_default` | `SajuLearnStreakBadge` exists, label contains "연속 3일" | AC6 |
| TU-L12 | `test_weeklyBanner_streakBadge_hidden_streakDays0` | `-sajuLearnStreakZero` launch → `SajuLearnStreakBadge` not exists | AC6 |
| TU-L13 | `test_weeklyBanner_completedTotalText` | staticTexts 중 "3 / 5강 완료" 포함 | AC6 |
| TU-L14 | `test_courseHeader_text` | `SajuLearnCourseHeader` label contains "입문 코스" and "7강 · 평균 3분" | AC8 |
| TU-L15 | `test_courseList_7cards_exist` | `SajuLearnLessonCard_L1` ~ `SajuLearnLessonCard_L7` 7개 exist | AC9 |
| TU-L16 | `test_lessonCard_completed_accessibilityLabel` | `SajuLearnLessonCard_L1` label contains "완료" | AC10 |
| TU-L17 | `test_lessonCard_current_continueLabel` | `SajuLearnLessonCard_L4` label contains "이어보기" | AC11 |
| TU-L18 | `test_lessonCard_locked_label` | `SajuLearnLessonCard_L5` label contains "잠김" | AC13 |
| TU-L19 | `test_lessonCard_completed_tap_pushesLesson` | `SajuLearnLessonCard_L1` 탭 → `SajuPlaceholderDestination_lesson` + id="L1" | AC14 |
| TU-L20 | `test_lessonCard_current_tap_pushesLesson` | `SajuLearnLessonCard_L4` 탭 → lesson route id="L4" | AC14 |
| TU-L21 | `test_lessonCard_locked_tap_showsToast` | `SajuLearnLessonCard_L5` 탭 → `SajuLearnToast` exist, label "이전 강의를 먼저 완료하세요" | AC15 |
| TU-L22 | `test_lessonCard_locked_tap_pathUnchanged` | 토스트 후 `SajuLearnListView` still on screen (not pushed) | AC15 |
| TU-L23 | `test_toast_autoDismiss_after2sec` | `SajuLearnLessonCard_L5` 탭 → 3초 후 `SajuLearnToast` not exist | AC15 |
| TU-L24 | `test_articleSection_visible_default` | `SajuLearnArticleSection` exists | AC16 |
| TU-L25 | `test_articleSection_2cards` | `SajuLearnArticleCard_A1`, `SajuLearnArticleCard_A2` exist | AC16 |
| TU-L26 | `test_articleSection_hidden_whenEmpty` | `-sajuLearnArticlesEmpty` launch → `SajuLearnArticleSection` not exist | AC16 |
| TU-L27 | `test_articleCard_tap_noNavigation` | `SajuLearnArticleCard_A1` 탭 → `SajuLearnListView` still exists | AC17 |
| TU-L28 | `test_hitTarget_pills_minSize44` | 6개 pill 버튼 frame.height ≥ 44 | AC19 |
| TU-L29 | `test_hitTarget_lessonCards_minSize44` | 7개 lesson card frame.height ≥ 44 | AC19 |
| TU-L30 | `test_hitTarget_articleCards_minSize44` | 2개 article card frame.height ≥ 44 | AC19 |
| TU-L31 | `test_dynamicType_xl_lessonCards_noTruncation` | `UIContentSizeCategoryOverride=UICTContentSizeCategoryXL` + lesson 카드 height > 44, indicator 28pt 유지 | AC20 |

---

## 7. Risks / Open Questions

1. **`WeeklyProgress.ratio` 이름 충돌**: 기존 `WeeklyProgress` struct는 Hashable이므로 stored property 추가 시 `init` 변경이 필요하다. `ratio`를 computed property로만 추가하면 기존 init 코드(`WeeklyProgress(completed:goal:streakDays:)`) 변경이 불필요하다 — 이 방향을 권장.

2. **기존 채택자 컴파일 보호**: `SajuLearningPathProviding`에 새 프로퍼티 3개를 추가할 때 default implementation 없이 추가하면 `MockSajuLearningPathProvider`와 다른 가능한 채택자들이 컴파일 오류가 발생한다. Protocol extension에 default 구현을 반드시 제공해야 한다.

3. **`SajuTabFoundationUITests.swift` T20 broken**: `.learn` 라우트를 placeholder에서 `SajuLearnListView`로 교체하면 T20 테스트가 `SajuPlaceholderDestination_learn`를 찾아 실패한다. Step 9에서 이 테스트를 업데이트한다.

4. **토스트 concurrent tap**: locked 카드를 빠르게 연속 탭 시 토스트 타이머가 중첩될 수 있다. `toastTask?.cancel()` 패턴(Swift Concurrency `Task`)으로 방어 — Step 6 `showLockedToast()` 구현에 포함.

5. **`SajuLearnListView` identifier 계층**: `ZStack`에 `.accessibilityIdentifier("SajuLearnListView")`를 부여하면 NavigationStack이 이를 올바르게 트리 노드로 노출하는지 확인 필요. 기존 `SajuElementsDetailView` 구현 방식(`accessibilityIdentifier`를 최외곽 뷰에 직접 부여)을 참고한다.

6. **VoiceOver `announcement` for toast**: `UIAccessibility.post(notification: .announcement, argument:)` 호출은 `UIKit import`를 요구한다. `SajuLearnListView.swift`에 `import UIKit` 또는 `import SwiftUI`(SwiftUI는 UIKit을 내재적으로 포함) 필요 여부 확인.

7. **`SajuLessonProviding.defaultTitles`에 L1~L7 추가 여부**: 현재 default titles는 `L-001`, `L-002`, `L-003`만 있다. WF4-06의 `LessonRow.id`는 `"L1"`~`"L7"` 등으로 계획. WF4-07(레슨 상세)에서 이 ID를 어떻게 처리할지 후속 슬라이스에서 결정; 현재 슬라이스에서는 `SajuPlaceholderDestinationView`가 id를 그대로 화면에 표시하므로 무관.

8. **pill 가로 스크롤 `padding` 처리**: `ScrollView` 내부에서 `.padding(.horizontal, 16)` 적용 시 pill content가 clipping될 수 있다. 부모 `VStack.padding(.horizontal, 16)`와 별도로, pill strip은 `ScrollView` 좌측 가장자리부터 시작해야 하므로 pill strip 뷰를 `padding(.horizontal, 16)` 범위 밖으로 빼거나, `ScrollView` 내부 HStack에 leading/trailing padding을 주는 방식 중 선택 필요. 구현 시 후자(HStack 내 첫/마지막 pill에 leading/trailing 16pt padding) 권장.
