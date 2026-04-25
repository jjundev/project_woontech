# WF1 온보딩 플로우 구현 플랜 (iOS SwiftUI)

## Context

운테크 iOS 앱의 최초 진입 플로우 **스플래시 → 온보딩 3단계 → 사주 입력 진입점**을 구현한다.
현재 `ios/` 하위에는 HTML/JSX 와이어프레임과 `spec.md`만 존재하고 Swift 코드/Xcode 프로젝트는 없다.
이번 작업은 **프로젝트 스캐폴딩 + WF1 전체 구현 + 테스트** 범위를 커버한다. 사주 입력(WF2)은 이 스펙 범위 밖이므로 **진입점 플레이스홀더**만 제공한다.

- **플랫폼**: iOS 17+, SwiftUI
- **스캐폴딩**: XcodeGen (`project.yml`) + Swift 소스 (사용자가 `xcodegen generate`로 `.xcodeproj` 생성)
- **참조 자산**: [ios/wireframes/screens-01-onboarding.jsx](../../wireframes/screens-01-onboarding.jsx)의 `ScrSplash`, `ScrOnboarding` 레이아웃을 SwiftUI로 충실히 재현
- **스펙 소스**: [ios/todo/WF1-onboarding/spec.md](spec.md) (FR/NFC/AC 번호 그대로 참조)

---

## 디렉토리 구조 (신규 생성)

```
ios/
├── project.yml                           # XcodeGen 설정
├── README.md                             # 빌드/실행 방법
├── Woontech/
│   ├── App/
│   │   ├── WoontechApp.swift             # @main 엔트리
│   │   └── RootView.swift                # Splash/Onboarding/Saju 플로우 스위처
│   ├── Features/
│   │   ├── Splash/
│   │   │   └── SplashView.swift          # 로고+타이틀+스피너, 1.5s 타이머
│   │   ├── Onboarding/
│   │   │   ├── OnboardingView.swift      # 3-step TabView + 인디케이터 + CTA
│   │   │   ├── OnboardingStepView.swift  # 개별 step 레이아웃 (일러스트+텍스트)
│   │   │   ├── OnboardingContent.swift   # step별 정적 콘텐츠 + LocalizedStringKey
│   │   │   ├── PageIndicatorView.swift   # 3개 도트, 활성 pill/비활성 circle, 탭
│   │   │   └── DisclaimerCheckboxView.swift  # step3 체크박스
│   │   └── SajuInput/
│   │       └── SajuInputPlaceholderView.swift  # WF2 진입점 스텁
│   ├── Shared/
│   │   ├── OnboardingStore.swift         # hasSeenOnboarding (@AppStorage 래퍼)
│   │   └── DesignTokens.swift            # 색상·간격 토큰 (WF.ink 등 대응)
│   └── Resources/
│       ├── Assets.xcassets/              # Logo, Illustration1/2/3 플레이스홀더
│       ├── ko.lproj/Localizable.strings  # 한국어 문자열
│       └── Info.plist
├── WoontechTests/
│   ├── OnboardingStoreTests.swift        # hasSeenOnboarding 영속화 유닛 테스트
│   └── OnboardingFlowStateTests.swift    # step/disclaimer/CTA 활성화 로직
└── WoontechUITests/
    └── OnboardingUITests.swift           # 전체 플로우 E2E
```

---

## 파일별 구현 개요

### `ios/project.yml`
- XcodeGen 스펙. iOS 17 deployment target, Swift 5.9, `Woontech`(앱), `WoontechTests`(유닛), `WoontechUITests`(UI) 3개 타겟.
- 번들 ID 예: `com.woontech.app`. `Resources/Info.plist` 참조.
- 스킴: 앱 실행 + 두 테스트 타겟 연결.

### `Woontech/App/WoontechApp.swift`
- `@main struct WoontechApp: App`.
- `WindowGroup { RootView() }`. `@StateObject var store = OnboardingStore()`를 `.environmentObject(store)`로 주입.

### `Woontech/App/RootView.swift`
- 상태: `enum Route { case splash, onboarding, sajuInput }`.
- `@State var route: Route = .splash`, `@EnvironmentObject var store: OnboardingStore`.
- Splash `onFinish` 콜백에서 `store.hasSeenOnboarding`에 따라 `.onboarding` / `.sajuInput` 분기 (FR-S3).
- OnboardingView `onComplete`에서 `store.markSeen()` 호출 후 `.sajuInput` 전환 (FR-N6, FR-R2).
- 전환 애니메이션 `withAnimation(.easeInOut(duration: 0.25))` (NFC-2).

### `Woontech/Features/Splash/SplashView.swift`
- 레이아웃(`ScrSplash` 재현): 로고 플레이스홀더(100×100), "운테크"(18pt bold), "오늘의 투자 태도를 점검하세요"(11pt muted), 24pt 원형 스피너(`ProgressView().progressViewStyle(.circular)`).
- `.task { try? await Task.sleep(for: .milliseconds(1500)); onFinish() }` (FR-S2).
- Safe area 준수, notch/home-indicator 침범 없음 (NFC-1).

### `Woontech/Features/Onboarding/OnboardingView.swift`
- `@State var step: Int = 1`, `@State var disclaimerChecked = false`.
- 최상단 `HStack { Spacer(); SkipButton(onTap: onComplete) }` — "건너뛰기" (FR-N2). Skip 탭 시 `onComplete()` 호출로 RootView에서 `markSeen()` + `.sajuInput` 전환.
- `TabView(selection: $step) { ForEach(1...3, id: \.self) { OnboardingStepView(step: $0) } }.tabViewStyle(.page(indexDisplayMode: .never))` — 좌/우 스와이프 자동 처리 (FR-N3).
  - step 1에서 우스와이프, step 3에서 좌스와이프는 TabView가 경계 차단 → FR-N3 두 번째 문장 자동 충족.
- `PageIndicatorView(current: $step, total: 3)` — 도트 탭으로 step 변경 (FR-N4). 탭은 `withAnimation { step = i }`.
- `step == 3`일 때 `DisclaimerCheckboxView(checked: $disclaimerChecked)` + CTA 하단 고지 문구(8pt muted) 노출 (FR-D1, FR-D5).
- CTA: `PrimaryButton(title: step == 3 ? "시작하기" : "다음", isEnabled: step != 3 || disclaimerChecked, action: ...)` (FR-O4, FR-D3/4).
  - step 1/2 → `withAnimation { step += 1 }`.
  - step 3 → 체크 상태에서만 `onComplete()` 호출, 아니면 no-op (AC-10).
- 모든 전환(스와이프/인디케이터/CTA)이 `$step` 단일 소스에 수렴하므로 자동 동기화 (FR-N5).

### `Woontech/Features/Onboarding/OnboardingStepView.swift`
- 입력: `step: Int`. 내부에서 `OnboardingContent.all[step - 1]` 조회.
- 레이아웃: 중앙 정렬 VStack — 일러스트(140×140, `Image(content.illustrationAsset)`) → 타이틀(16pt bold) → 서브텍스트(11pt muted, `.multilineTextAlignment(.center)`, `\n` 줄바꿈 포함).
- `.accessibilityElement(children: .combine)` + `.accessibilityLabel(Text("\(title). \(body)"))` (NFC-3).

### `Woontech/Features/Onboarding/OnboardingContent.swift`
- `struct OnboardingContent { let titleKey: LocalizedStringKey; let bodyKey: LocalizedStringKey; let illustrationAsset: String }`.
- `static let all: [OnboardingContent] = [ ... 3개 ... ]` — `Localizable.strings` 키 참조 (NFC-5).

### `Woontech/Features/Onboarding/PageIndicatorView.swift`
- 3개 `Button`. 활성: `RoundedRectangle(cornerRadius: 3).frame(width: 16, height: 6).foregroundStyle(DesignTokens.ink)`. 비활성: `Circle().frame(width: 6, height: 6).foregroundStyle(DesignTokens.gray2)`.
- 각 Button을 `.frame(width: 44, height: 44)` 투명 컨테이너로 감싸고 `.contentShape(Rectangle())` 지정 → 44×44 hit target (NFC-4).
- `.accessibilityLabel(Text("\(index)번째 페이지로 이동"))`, `.accessibilityAddTraits(isActive ? .isSelected : [])` (NFC-3).
- 탭: `withAnimation(.easeInOut(duration: 0.25)) { current = index }` (NFC-2).

### `Woontech/Features/Onboarding/DisclaimerCheckboxView.swift`
- `@Binding var checked: Bool`. HStack — 16×16 체크박스(체크: ink 채움+흰 체크마크, 해제: 1.5pt 보더만) + 10pt 텍스트 "본 앱은 학습·참고용이며 투자 권유가 아닙니다.".
- 전체를 `Button`으로 감싸 탭 시 `checked.toggle()`. `.accessibilityAddTraits(checked ? [.isButton, .isSelected] : .isButton)`.
- 기본값 해제 (FR-D2). 뷰 로컬 `@State`에 저장 → 재진입/재설치 시 자동 초기화 (FR-D6).

### `Woontech/Features/SajuInput/SajuInputPlaceholderView.swift`
- 단순 플레이스홀더: "사주 입력 (WF2)" 중앙 텍스트 + `accessibilityIdentifier("SajuInputRoot")` (UI 테스트 랜딩 검증용). 실제 구현은 Out of Scope.

### `Woontech/Shared/OnboardingStore.swift`
- `final class OnboardingStore: ObservableObject { @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false; func markSeen() { hasSeenOnboarding = true } }` (FR-R1, FR-R3).
- 테스트용 init(suite: UserDefaults)로 격리 오버라이드 가능하게 설계.

### `Woontech/Shared/DesignTokens.swift`
- `enum DesignTokens { static let ink = Color(hex: 0x1A1A1A); static let muted = ...; static let gray2 = ...; static let bg = ... }` — JSX `WF.*` 매핑.

### `Woontech/Resources/ko.lproj/Localizable.strings`
- 모든 사용자 노출 문자열 키. spec FR-O1 문자열을 바이트 단위 그대로 사용 (AC-2).
  - `splash.title`, `splash.subtitle`
  - `onboarding.1.title`, `onboarding.1.body`, …, `onboarding.3.body`
  - `onboarding.skip`, `onboarding.cta.next`, `onboarding.cta.start`
  - `onboarding.disclaimer.checkbox`, `onboarding.disclaimer.footer`

### `Woontech/Resources/Assets.xcassets`
- 이미지 세트: `logo`, `illustration_1`, `illustration_2`, `illustration_3` (NFC-6). 임시 투명/회색 1× PNG.

---

## 테스트 계획

### `WoontechTests/OnboardingStoreTests.swift` (유닛)
- `test_default_hasSeenOnboarding_isFalse`
- `test_markSeen_setsFlagTrue_andPersists` — 격리된 `UserDefaults(suiteName:)` 주입 후 검증.

### `WoontechTests/OnboardingFlowStateTests.swift` (유닛)
- 상태 전환 로직을 얇은 `OnboardingFlowModel`(@Observable)로 분리해 테스트:
  - `ctaEnabled`: step 1/2 항상 true, step 3은 `disclaimerChecked` 종속 (FR-D3/4, AC-8/9/10).
  - `ctaLabelKey`: step 3일 때 `onboarding.cta.start`, 그 외 `onboarding.cta.next` (FR-O4).

### `WoontechUITests/OnboardingUITests.swift` (XCUITest)
- `test_coldLaunch_showsSplash_thenOnboarding1` — 1.5s 대기 후 step1 타이틀 존재 (AC-1).
- `test_ctaTap_movesStep1_to_Step2_to_Step3` (AC-3).
- `test_leftSwipe_advancesStep_rightSwipeReturns` (AC-4).
- `test_swipeBoundaries_step1Right_step3Left_noop` (AC-5).
- `test_indicatorTap_jumpsToStep` (AC-6).
- `test_skipTap_anyStep_goesToSajuInput_andPersistsFlag` (AC-7).
- `test_step3_disclaimerUnchecked_ctaDisabled_tapNoop` (AC-8, AC-10).
- `test_step3_checkToggle_enablesAndDisablesCTA` (AC-9).
- `test_step3_checkedStart_navigatesSaju_andPersistsFlag` (AC-11).
- `test_relaunch_whenFlagTrue_bypassesOnboarding` — `app.launchArguments = ["-hasSeenOnboarding", "YES"]` 주입 (AC-12).
- `test_accessibility_hitTargets_minimum44pt` — Skip/인디케이터 버튼 프레임 측정 (NFC-4, AC-14).
- `test_voiceOverLabels_present` — CTA/Skip/Dot/Checkbox label·trait 검증 (NFC-3, AC-13).

---

## End-to-End 검증 절차

1. **스캐폴딩**: `cd ios && xcodegen generate` → `Woontech.xcodeproj` 생성, Xcode 로드 에러 없음.
2. **빌드**: `xcodebuild -project ios/Woontech.xcodeproj -scheme Woontech -destination 'platform=iOS Simulator,name=iPhone 15' build`.
3. **유닛 테스트**: `xcodebuild test ... -only-testing:WoontechTests`.
4. **UI 테스트**: `xcodebuild test ... -only-testing:WoontechUITests` → AC-1~14 자동 검증.
5. **수동 스모크** (iOS 17 시뮬레이터):
   - 앱 삭제 후 재설치 → 스플래시 1.5s → 온보딩 1 노출.
   - 스와이프 / 인디케이터 탭 / "다음" CTA로 step 이동 확인.
   - step 3 체크박스 OFF: "시작하기" 비활성(회색). ON 전환 시 활성 → 탭 → 사주 플레이스홀더 진입.
   - 앱 재실행 → 스플래시 후 바로 사주 플레이스홀더 (온보딩 건너뜀).
   - VoiceOver on → 각 요소 포커스·상태 트레잇 확인.

---

## Out of Scope

- 사주 입력 WF2 각 step 구현 (플레이스홀더 뷰만).
- 회원가입/소셜 OAuth, 다크모드, 영어 로케일, 원격 콘텐츠 설정.
- 실제 로고/일러스트 아트워크 (플레이스홀더 키만 등록).
- 온보딩 A/B 테스트, 애널리틱스 이벤트 정의.
