# Implementation Plan — WF2 사주 입력 + 투자 성향 결과 플로우 (v1)

## 1. Goal

WF1 온보딩을 마친 사용자가 **6단계 사주 입력 → 분석 로더 → 단일 결과 화면 → 가입 유도 → 친구 초대 진입점**까지 끊김 없이 이어지는 SwiftUI 플로우를 구현한다. 입력값은 로컬에 영속화되고, 결과 화면은 Aha 모먼트(유형/원국/오행/강점/주의/접근)를 단일 스크롤로 제공한다.

## 2. Affected Files

### New — Domain / State
- `Woontech/Shared/SajuInputModel.swift` — 사주 입력값(성별·이름·생년월일·시간·출생지·진태양시) 구조체 + 유효성/파생값.
- `Woontech/Shared/SajuFlowModel.swift` — 스텝 1~8.5 네비게이션 상태머신(현재 스텝, 진행률, 스킵 규칙, 뒤로/다음).
- `Woontech/Shared/SajuInputStore.swift` — `@MainActor ObservableObject`. `SajuInputModel` + `SajuFlowModel` + 분석 결과를 소유, `UserDefaults` 영속화.
- `Woontech/Shared/CityCatalog.swift` — 국내 시/도 고정 경도 테이블(서울·부산·인천·대구·광주·대전 + 기본 검색용 시·군·구 데이터).
- `Woontech/Shared/SajuAnalysisEngine.swift` — 진태양시 보정·4주·오행 계산 래퍼(1차 릴리스는 결정적 스텁 + 인터페이스). `algorithm_of_saju.md`(별도) 규칙에 따른 절입시 처리 훅.
- `Woontech/Shared/SajuResultModel.swift` — 유형명, 일주/십성 요약, 오행 막대, 강점/주의/접근 불릿, 정확도 배지 enum.
- `Woontech/Shared/SolarTimeCalculator.swift` — 경도·표준시 차이(분)·보정 출생시 계산.
- `Woontech/Shared/ShareCardRenderer.swift` — SwiftUI View → `UIImage`(`ImageRenderer`, 1080×1920) 변환 헬퍼.

### New — UI (Features/SajuInput)
- `Features/SajuInput/SajuInputFlowView.swift` — 루트 컨테이너. 상단 진행 바, 백 버튼, 스텝 스위처, 하단 고정 CTA.
- `Features/SajuInput/StepProgressBarView.swift` — 1/6~6/6 진행 바.
- `Features/SajuInput/Steps/Step1GenderView.swift` — 남/여 선택 박스.
- `Features/SajuInput/Steps/Step2NameView.swift` — 이름 텍스트 필드(20자 제한, 공백 트리밍).
- `Features/SajuInput/Steps/Step3BirthDateView.swift` — 양/음력 세그먼트, 윤달 체크박스, 3-column 휠 피커.
- `Features/SajuInput/Steps/Step4BirthTimeView.swift` — 2-column 휠 + "시간을 모르겠어요" 체크박스.
- `Features/SajuInput/Steps/Step5BirthPlaceView.swift` — 검색 박스, 기본 도시 리스트, 국외 경도 입력.
- `Features/SajuInput/Steps/Step6SolarTimeView.swift` — 진태양시 토글, 계산 결과 박스, "진태양시가 뭔가요?" 바텀시트.
- `Features/SajuInput/Steps/Step7LoaderView.swift` — 프로그레스 바, 팁 캐러셀, 최소 1.8초 보장.
- `Features/SajuInput/Result/Step8ResultView.swift` — 단일 스크롤 결과 화면(Hero + 원국 + 오행 + 강점/주의/접근 + 수정 + CTA).
- `Features/SajuInput/Result/HeroTypeCardView.swift`
- `Features/SajuInput/Result/SajuMiniChartView.swift`
- `Features/SajuInput/Result/WuxingBalanceBarView.swift`
- `Features/SajuInput/Result/BulletListView.swift` — 강점/주의/접근 공용.
- `Features/SajuInput/Result/AccuracyBadgeView.swift`
- `Features/SajuInput/Result/ShareCardView.swift` — Step 8 공유·Step 10 미리보기 공용.
- `Features/SajuInput/SignUp/Step85SignUpView.swift` — "결과 저장하기" 회원가입 유도.
- `Features/SajuInput/Referral/Step10ReferralView.swift` — 친구 초대 화면(홈 진입점이 아직 없으므로 이번 WF에선 **뷰만** 구현 + 디버그 진입점 유지).
- `Features/SajuInput/Shared/SajuCheckbox.swift`, `SajuSegmented.swift`, `SajuToggleRow.swift`, `WheelPicker.swift` 등 공용 컴포넌트.
- `Features/Home/HomePlaceholderView.swift` — WF3 자리표시자(결과 이후 비회원 "나중에 하기" 착지점). `SajuInputPlaceholderView` 스타일 준용.

### Modified
- `Woontech/App/RootView.swift` — `Route`에 `.home` 추가. `.sajuInput`은 `SajuInputFlowView`로 교체. 기존 placeholder는 제거.
- `Woontech/App/WoontechApp.swift` — `SajuInputStore`를 `@StateObject`로 추가하여 `environmentObject` 주입. UI 테스트용 launch args(`-resetSajuInput`, `-sajuStartStep <N>`) 추가.
- `Woontech/Features/SajuInput/SajuInputPlaceholderView.swift` — 제거(또는 빈 파일로 축소 후 RootView에서 참조 제거). UI 테스트의 `SajuInputRoot` 식별자는 **첫 스텝(Step1Gender) 루트 컨테이너에 이관**하여 기존 OnboardingUITests가 계속 통과하도록 보장.
- `Woontech/Resources/ko.lproj/Localizable.strings` — 스펙의 모든 한국어 리터럴을 `saju.*` 키로 추가.
- `WoontechTests/` 디렉터리 — 신규 테스트 파일(아래 5절 참조).
- `WoontechUITests/` 디렉터리 — 신규 UI 테스트 파일(아래 6절 참조).
- `Woontech.xcodeproj/project.pbxproj` — 신규 파일 등록, 타깃 멤버십, 리소스 번들링.

## 3. Data Model / State Changes

### 3.1 `SajuInputModel`
```
enum Gender { case male, female }
enum CalendarKind { case solar, lunar(leap: Bool) }
struct BirthDate { year, month, day; kind: CalendarKind }
struct BirthTime { hour: Int; minute: Int; hourKnown: Bool }  // hourKnown=false → hour/minute 무시
enum BirthPlace { case domestic(cityID: String); case overseas(longitude: Double) }
struct SolarTimeCorrection { enabled: Bool }  // 기본 true

struct SajuInputModel {
    var gender: Gender?
    var name: String = ""
    var birthDate: BirthDate = .default(1990/03/15, .solar)
    var birthTime: BirthTime = .init(hour: 12, minute: 0, hourKnown: true)
    var birthPlace: BirthPlace = .domestic("SEOUL")
    var solarTime: SolarTimeCorrection = .init(enabled: true)

    // Derived
    var normalizedName: String { name.trimmingCharacters(in: .whitespaces) }
    var displayNameLabel: String  // FR-8.3
    var accuracy: AccuracyLevel   // FR-8.4
}
```

### 3.2 `SajuFlowModel`
- `currentStep: SajuStep` where `SajuStep = .gender | .name | .birthDate | .birthTime | .birthPlace | .solarTime | .loader | .result | .signUp | .referral`.
- `inputSteps: [SajuStep]` = 1~6. 진행 바 `1/6 … 6/6`.
- `canAdvance(from:using input:) -> Bool` — 각 스텝의 FR 활성화 조건 구현.
- `next(from:)` — Step 5 완료 시 `input.birthTime.hourKnown == false`이면 Step 6을 스킵하고 `.loader`로 이동(FR-6.5 / AC-10).
- `back(from:)` — Step 1에서 호출 시 `onExit` 콜백으로 홈 복귀.
- `jump(to editableStep:)` — Step 8 "수정" CTA에서 사용. `returnToResult = true` 플래그 세팅.
- `hasCompletedFlow: Bool` / `isLoaderMinimumElapsed: Bool`.

### 3.3 `SajuInputStore`
- `@Published input: SajuInputModel`, `flow: SajuFlowModel`, `result: SajuResultModel?`.
- `persist()` — FR-NFC-6: Step 8 진입 시 `UserDefaults` key `userProfile`에 JSON 인코딩 저장.
- `load()` — 앱 시작 시 복원(테스트 격리 위해 `UserDefaults` 주입).
- `resetForUITests()` — `-resetSajuInput` launch arg에서 호출.
- `startAnalysis()` — `SajuAnalysisEngine.analyze`를 백그라운드 태스크로 수행, 로더 최소 1.8초 대기 후 `.result`로 전환.

### 3.4 `UserDefaults` 키
- `userProfile` (NFC-6).
- `sajuResultCache` (수정 후 재분석 시 비교용, 선택).

### 3.5 라우팅 추가(`RootView`)
- `Route`: `splash → onboarding → sajuInput(flow) → home`. "나중에 하기" 또는 분석 후 홈 이동 시 `.home`.
- Step 10은 **홈의 진입점**이 없으므로, 1차 릴리스에서는 `.referral` 라우트를 제공하되 자동 진입 없음(FR-10.1, AC-23).

## 4. Implementation Steps (ordered, each independently testable)

1. **스토어/모델 스캐폴딩**
   - `SajuInputModel`, `SajuFlowModel`, `SajuInputStore`, `AccuracyLevel` enum, `CityCatalog`(6개 기본 도시)까지 순수 Swift 타입 작성. 단위 테스트를 먼저 붙여 TDD로 진행.
2. **진태양시 계산기**
   - `SolarTimeCalculator.correct(longitude:standardMeridian:at:)` 구현. 서울(127.0°) 기준 표준시(135°) 차이 ≈ −32분 검증.
3. **분석 엔진 스텁**
   - `SajuAnalysisEngine.analyze(input:) -> SajuResultModel` — 결정적(입력 해시 기반) 스텁 데이터로 유형명/오행/강점 등 반환. 실제 명리 계산은 `algorithm_of_saju.md` 연동 훅만 마련(out-of-scope 경계 준수).
4. **공용 UI 컴포넌트**
   - `StepProgressBarView`, `WheelPicker`, `SajuCheckbox`, `SajuSegmented`, `SajuToggleRow`. 각 컴포넌트 snapshot-free 단위 검증.
5. **Flow 컨테이너**
   - `SajuInputFlowView`: 상단 뒤로 버튼(44×44pt), 진행 바, 스텝 스위치(`switch store.flow.currentStep`), 하단 고정 CTA(`PrimaryButton` 재사용, 라벨 "다음"/"사주 분석 시작").
6. **Step 1 — 성별** (FR-1.x, AC-1,2)
7. **Step 2 — 이름** (FR-2.x, AC-3) — 입력 바인딩에서 20자 트리밍 & 공백 무시.
8. **Step 3 — 생년월일** (FR-3.x, AC-4,5) — `WheelPicker` 3-column, 음력/윤달 규칙은 `LunarCalendar.hasLeapMonth(year:month:)` 헬퍼.
9. **Step 4 — 태어난 시간** (FR-4.x, AC-6,7) — 체크박스 토글 시 휠 비활성화.
10. **Step 5 — 출생지** (FR-5.x, AC-8,9) — 기본 도시 리스트 + 검색(로컬 필터) + 국외 경도 입력(NumberFormatter로 −180~180 제한).
11. **스킵 규칙 연결** (FR-6.5 / AC-10) — Step 5 → Step 7 직접 전환.
12. **Step 6 — 진태양시 보정** (FR-6.x, AC-11,12,13) — 토글, 계산 결과 박스, `BottomSheet` modal(`.presentationDetents(.fraction(0.45))`).
13. **Step 7 — 로더** (FR-7.x, AC-14) — `TimelineView`로 진행률 보간, 팁 3개 2.5s 페이드, 최소 1.8s 보장 로직(`Task.sleep`).
14. **Step 8 — 결과 화면** (FR-8.x, AC-15~20) — `ScrollView` + 각 섹션 뷰, "수정" 탭 → `flow.jump(to:)`, "공유하기" → `ShareCardRenderer` → `UIActivityViewController`(`UIViewControllerRepresentable`).
15. **영속화** (NFC-6) — Step 8 렌더 시 `store.persist()` 1회 호출.
16. **Step 8.5 — 회원가입 유도** (FR-8.5.x, AC-21,22) — Apple/Google/이메일 버튼은 현재는 no-op + print. "나중에 하기" → `.home`.
17. **Step 10 — 친구 초대 뷰** (FR-10.x, AC-23~25) — 공유 카드 미리보기, 5자리 초대 코드(프로필에서 유도), "링크 복사" → `UIPasteboard.general.string = https://woontech.app/invite/{CODE}` + 토스트. 홈 진입점 없음 → 1차에선 디버그 스토리보드 진입만.
18. **RootView 라우팅 갱신 및 placeholder 제거** — 기존 `SajuInputRoot` 식별자를 Step 1 컨테이너로 이관하여 OnboardingUITests 회귀 방지.
19. **Localization 채우기** — 모든 리터럴 `saju.*` 키로 이동. ko.lproj 추가.
20. **접근성 보강** (NFC-4,5) — VoiceOver 레이블/트레잇, hit-target 44×44pt, 휠 피커 현재값 announce.
21. **UI 테스트 launch args** — `-resetSajuInput`, `-sajuStartStep <N>`, `-preloadedProfile <JSON>`.
22. **Edge 케이스** — 이름 10자 초과 말줄임(FR-8.3), hourKnown=false 시주 대시 렌더링(FR-8.5, AC-18).

## 5. Unit Test Plan (per Functional Requirement)

파일: `WoontechTests/SajuInputModelTests.swift`, `SajuFlowModelTests.swift`, `SolarTimeCalculatorTests.swift`, `SajuAnalysisEngineTests.swift`, `CityCatalogTests.swift`, `SajuInputStorePersistenceTests.swift`, `SajuResultAccuracyTests.swift`.

| Test | FR Covered |
|---|---|
| `test_flow_step1_startsAtOneOfSix` | FR-C1 |
| `test_flow_progress_updatesWithStep` | FR-C1 |
| `test_flow_back_fromStep1_triggersExit` | FR-C2 |
| `test_flow_ctaLabel_step1to5_next_step6_startAnalysis` | FR-C3 |
| `test_flow_isCTAEnabled_gender_requiresSelection` | FR-1.3, FR-C4 |
| `test_flow_swipeNavigation_notExposed` (API shape) | FR-C5 |
| `test_input_name_trimming_limit20chars_activates` | FR-2.4 |
| `test_input_birthDate_default_1990_03_15_solar` | FR-3.4 |
| `test_input_birthDate_yearRange_1900_toCurrent` | FR-3.5 |
| `test_input_birthDate_invalidDays_filtered` (Feb 30, Apr 31) | FR-3.6 |
| `test_input_lunar_leapMonth_toggle_availability` | FR-3.3 |
| `test_input_birthDate_isCTAEnabled_default` | FR-3.7, AC-4 |
| `test_input_birthTime_hourKnownFalse_disablesPicker` | FR-4.3, FR-4.4 |
| `test_input_birthTime_ctaEnabledWhenKnownOrUnknown` | FR-4.5 |
| `test_flow_skipsStep6_whenHourUnknown` | FR-6.5, AC-10 |
| `test_input_birthPlace_default_seoul_enablesCTA` | FR-5.3 |
| `test_input_birthPlace_overseas_longitudeRange` (−180, 180, 0, NaN, 200) | FR-5.5, FR-5.6 |
| `test_cityCatalog_searchFiltersByPrefix` | FR-5.4 |
| `test_solarTime_default_ON` | FR-6.3 |
| `test_solarTime_calculatedValues_forSeoul` (경도 127 → −32분) | FR-6.4, AC-11 |
| `test_solarTime_toggleOff_outputsNotApplied` | FR-6.4, AC-11 |
| `test_analysisEngine_minimum1_8sGuaranteed` (using injected clock) | FR-7.5, AC-14 |
| `test_analysisEngine_returnsDeterministicResult` | FR-8.2 |
| `test_result_displayLabel_truncatesOver10chars` | FR-8.3, AC-16 |
| `test_result_displayLabel_fallback_whenNameEmpty` | FR-8.3, AC-16 |
| `test_result_accuracyBadge_rules` (시간·출생지·진태양시 조합 매트릭스) | FR-8.4, AC-17 |
| `test_result_miniChart_hourUnknownColumn_isBlank` | FR-8.5, AC-18 |
| `test_store_persist_writesUserProfileJSON` | NFC-6 |
| `test_store_load_restoresProfile` | NFC-6 |
| `test_referral_inviteCode_isFiveAlnumChars_stable` | FR-10.2 |
| `test_referral_inviteURL_format` | FR-10.8, AC-25 |
| `test_localization_allKeysPresent_inKoLProj` | NFC-7 |
| `test_disclaimer_containsRequiredSentence` | NFC-8, AC-28 |

## 6. UI Test Plan (per Acceptance Criterion — 작성만, 구현자는 미실행)

파일: `WoontechUITests/SajuInputUITests.swift`, `SajuResultUITests.swift`, `SajuSignUpUITests.swift`, `SajuReferralUITests.swift`, `SajuAccessibilityUITests.swift`.

런처 인자: `-resetOnboarding`, `-hasSeenOnboarding YES`, `-resetSajuInput`, `-sajuStartStep <1-10>`, `-preloadedProfile <json>`.

| UI Test | AC |
|---|---|
| `test_step1_progressBar_showsOneOfSix_onEntry` | AC-1 |
| `test_step1_cta_disabledUntilGenderSelected` | AC-2 |
| `test_step2_name_empty_disablesCta_validLengthEnables_maxTruncates20` | AC-3 |
| `test_step3_defaults_1990_03_15_solar_ctaEnabled` | AC-4 |
| `test_step3_lunar_showsLeapCheckbox_yearRange_invalidDatesFiltered` | AC-5 |
| `test_step4_wheelSelection_enablesCta` | AC-6 |
| `test_step4_unknownCheckbox_disablesWheel_enablesCta_setsModelFlag` | AC-7 |
| `test_step5_defaultSeoul_ctaEnabled` | AC-8 |
| `test_step5_overseas_longitudeBounds_validation` | AC-9 |
| `test_flow_skipsStep6_whenHourUnknown` | AC-10 |
| `test_step6_defaultToggleOn_showsCalculatedBox_toggleOffShowsNotApplied` | AC-11 |
| `test_step6_whatsTrueSolarTime_openAndDismissBottomSheet` | AC-12 |
| `test_step6_startAnalysisCta_movesToLoader` | AC-13 |
| `test_loader_showsProgress_tips_rotated_minimum1_8seconds` | AC-14 |
| `test_result_sectionsInOrder_hero_origin_wuxing_strength_caution_approach_input` | AC-15 |
| `test_result_heroLabel_longName_truncates_emptyFallback` | AC-16 |
| `test_result_accuracyBadge_high_medium_mediumWithAddTimeCta` | AC-17 |
| `test_result_hourUnknown_miniChartHourColumn_dashed` | AC-18 |
| `test_result_editButton_returnsToStep_appliesChange_reRendersResult` | AC-19 |
| `test_result_share_opensActivityViewController_with1080x1920Image` | AC-20 |
| `test_result_start_movesToSignUp_whenNotLoggedIn` | AC-21 |
| `test_signUp_laterLink_movesToHome_keepsResultInSession` | AC-22 |
| `test_referral_notAutoEntered_afterResultFlow` | AC-23 |
| `test_referral_displaysCodeAndPreview_matchingProfile` | AC-24 |
| `test_referral_copyLink_putsInviteUrlOnPasteboard_showsToast` | AC-25 |
| `test_voiceOver_labelsAndTraits_onAllInputs` (gender, name, wheels, checkbox, toggle, CTA) | AC-26 |
| `test_hitTargets_backButton_toggle_checkbox_editButton_atLeast44pt` | AC-27 |
| `test_result_disclaimer_containsStudyPhrase` | AC-28 |

회귀 보호: 기존 `OnboardingUITests`의 `SajuInputRoot` 식별자는 Step 1 컨테이너에 이관해야 한다. 이관을 확인하는 smoke test (`test_onboardingComplete_landsOnSajuInputRoot`)를 추가.

## 7. Risks / Open Questions

1. **실제 명리 계산 엔진** — `algorithm_of_saju.md`와 Swiss Ephemeris 연동은 별도 스펙. 1차 릴리스는 결정적 스텁으로 UI·테스트를 안정화하고, 엔진 교체 시 동일 `SajuAnalysisEngine` 인터페이스로 교체 가능하게 둔다.
2. **음력 → 양력 변환** — iOS `Calendar(identifier: .chinese)`로 충분한지, 윤달 처리와 절입시(예: 경칩) 경계 케이스에서 오차가 없는지 확인 필요. 1차는 `Calendar.chinese` + leap-month 플래그로 처리.
3. **Step 10 진입점** — 스펙 상 홈의 배너/세팅에서만 진입(FR-10.1)인데 홈(WF3)은 Out of Scope. → 이번 WF에서는 뷰만 구현하고 디버그/테스트용 진입 경로만 노출. 실제 배치는 WF3 스펙에서 연결.
4. **공유 카드 1080×1920 렌더링** — `ImageRenderer`의 스케일(`@3x`)과 고정 사이즈 강제 방식. SwiftUI `frame(width:height:)` + `environment(\.displayScale, 3)` 검증 필요.
5. **바텀시트 API 버전** — `.presentationDetents`는 iOS 16+. 타깃 최소 버전 확인(Onboarding 코드는 이미 iOS 16+ 가정). iOS 15 지원 시 커스텀 바텀시트 구현 필요.
6. **국외 출생 경도 입력 UX** — 키보드 타입(decimal), 로케일별 소수점(.,), 입력 마스킹. 1차는 `.decimalPad` + Locale-aware 포맷터.
7. **Apple/Google/Kakao 실제 인증** — Out of Scope. 1차는 no-op 버튼 + TODO 마커.
8. **"수정" 왕복 후 재분석** — 이름만 변경 시 유형이 바뀌면 UX 혼란 가능. 스텁 엔진에서는 이름은 라벨에만 영향, 유형은 생년월일·시간·출생지 해시로 고정되게 설계.
9. **기존 OnboardingUITests 회귀** — `SajuInputRoot` 식별자 이관 누락 시 `skip/finish` 테스트가 깨진다. 구현자는 구 placeholder 삭제와 식별자 이관을 **동일 커밋**에서 처리해야 한다.
10. **UserDefaults vs Core Data** — 스펙은 선택 여지를 주지만(NFC-6), 1차 릴리스는 `UserDefaults` + Codable JSON으로 간소화. 향후 마이그레이션 경로는 별도 스펙.
11. **절입시 월주 경계** — 스텁 단계에서는 단순 월 기반. 실제 계산 도입 시 day-level 경계 테스트 필수.

PLAN_WRITTEN
