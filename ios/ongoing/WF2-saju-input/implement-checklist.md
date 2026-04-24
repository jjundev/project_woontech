# Implementation Checklist — WF2 사주 입력 + 투자 성향 결과 플로우

This is the authoritative checklist the implementor and reviewers must use.
Every `[ ]` item must be addressed before the plan is considered complete.

## Requirements (from spec)

### 공통 네비게이션
- [ ] R-C1: Step 1~6 상단 진행 바가 현재 스텝에 따라 1/6 → 6/6까지 채워진다. (FR-C1, AC-1)
- [ ] R-C2: 각 스텝 상단에 뒤로 버튼이 있고, Step 1 뒤로 누르면 온보딩 종료 지점/홈으로 복귀한다. (FR-C2)
- [ ] R-C3: Step 1~5 CTA 라벨 "다음", Step 6 CTA 라벨 "사주 분석 시작". (FR-C3)
- [ ] R-C4: 각 스텝 필수 입력 충족 전까지 CTA 비활성. (FR-C4)
- [ ] R-C5: 좌/우 스와이프 및 인디케이터 탭 이동은 제공하지 않는다. (FR-C5)

### Step 1 — 성별
- [ ] R1: "성별을 선택해주세요" 타이틀 + "사주 해석의 기본 정보예요" 힌트 표시. (FR-1.1)
- [ ] R2: 남/여 선택 박스 좌우 배치, 탭 시 강조 테두리 + 볼드, 타측 해제. (FR-1.2)
- [ ] R3: 선택 전까지 "다음" 비활성. (FR-1.3, AC-2)

### Step 2 — 이름
- [ ] R4: "이름을 알려주세요" 타이틀 + "사주 리포트에 표시됩니다" 힌트. (FR-2.1)
- [ ] R5: 단일 텍스트 필드, 포커스 시 iOS 키보드. (FR-2.2)
- [ ] R6: "본명이 아니어도 괜찮아요" 보조 문구. (FR-2.3)
- [ ] R7: 공백 제외 1자 이상이면 활성화, 최대 20자 자동 트리밍. (FR-2.4, AC-3)

### Step 3 — 생년월일
- [ ] R8: "언제 태어나셨나요?" 타이틀 + "사주 분석의 가장 중요한 정보예요" 힌트. (FR-3.1)
- [ ] R9: 양력/음력 2버튼 세그먼트, 기본 양력. (FR-3.2, AC-4)
- [ ] R10: 음력 선택 시 "윤달" 체크박스 표시, 해당 월 윤달 없으면 비활성. (FR-3.3, AC-5)
- [ ] R11: 3-column 휠(연/월/일), 기본 1990/03/15. (FR-3.4, AC-4)
- [ ] R12: 연도 범위 1900 ~ 당해. (FR-3.5, AC-5)
- [ ] R13: 존재하지 않는 날짜(2/30 등) 선택 불가. (FR-3.6, AC-5)
- [ ] R14: 기본값 세팅으로 첫 진입 시 CTA 활성. (FR-3.7, AC-4)

### Step 4 — 태어난 시간
- [ ] R15: "몇 시에 태어나셨나요?" 타이틀 + "시주는 사주의 네 기둥 중 하나예요" 힌트. (FR-4.1)
- [ ] R16: 2-column 휠(시/분), 15분 간격 기본 + 임의 분(50분 등) 포함. (FR-4.2)
- [ ] R17: "시간을 모르겠어요 (시주 없이 3주 기반 분석)" 체크박스. (FR-4.3)
- [ ] R18: 체크 시 휠 비활성화(탭 불가·흐린 색), `hourKnown = false` 기록. (FR-4.4, AC-7)
- [ ] R19: 휠 선택 또는 체크 중 하나면 CTA 활성. (FR-4.5, AC-6, AC-7)

### Step 5 — 출생지
- [ ] R20: "어디서 태어나셨나요?" 타이틀 + "진태양시 보정에 사용돼요" 힌트. (FR-5.1)
- [ ] R21: 돋보기 아이콘 + 텍스트 필드 검색 박스. (FR-5.2)
- [ ] R22: 기본 도시 리스트(서울/부산/인천/대구/광주/대전) 표시, 첫 진입 시 서울 선택. (FR-5.3, AC-8)
- [ ] R23: 검색 입력 시 국내 시/군/구 자동완성 리스트 + 탭 선택. (FR-5.4)
- [ ] R24: "국외 출생 (경도 직접 입력)" 체크박스, 체크 시 도시 리스트 대신 경도 입력 필드(소수 2자리). (FR-5.5)
- [ ] R25: 도시 선택 또는 −180.00~180.00 범위 경도 유효 시 CTA 활성. (FR-5.6, AC-9)

### Step 6 — 진태양시 보정
- [ ] R26: "진태양시로 보정할까요?" 타이틀 + "표준시와 실제 태양시의 차이를 보정해요" 힌트. (FR-6.1)
- [ ] R27: "진태양시가 뭔가요? →" 링크 → 바텀 시트(3 카드), 외부 탭/확인 버튼으로 닫기. (FR-6.2, AC-12)
- [ ] R28: "진태양시 보정" 토글 스위치 + "정확한 분석을 위해 권장" 보조 문구, 기본 ON. (FR-6.3, AC-11)
- [ ] R29: "계산 결과" 박스에 경도·표준시 차이(분)·보정된 출생시 표시, 토글 OFF 시 "미적용". (FR-6.4, AC-11)
- [ ] R30: `hourKnown = false`이면 Step 6 스킵, Step 7으로 직접. (FR-6.5, AC-10)
- [ ] R31: "사주 분석 시작" CTA 항상 활성, 탭 시 Step 7로 전환. (FR-6.6, AC-13)

### Step 7 — 분석 로더
- [ ] R32: 중앙 애니메이션 + "사주를 분석 중입니다" + "{YYYY}년 {M}월 {D}일생의 원국을 계산하고 있어요" 서브문구. (FR-7.1)
- [ ] R33: 프로그레스 바 0% → 100% + 퍼센트 숫자, 분석 완료 시 100%. (FR-7.2)
- [ ] R34: 명리학 팁 카드 3개를 2.5초 간격 페이드 교체 + 도트 인디케이터. (FR-7.3)
- [ ] R35: 하단 "Swiss Ephemeris 기반 정밀 계산 중" 크레딧. (FR-7.4)
- [ ] R36: 최소 표시 1.8초 보장. (FR-7.5, AC-14)
- [ ] R37: 로더 중 뒤로 제스처 무시, 완료 시 Step 8 자동 전환. (FR-7.6)

### Step 8 — 결과 (나의 투자 성향)
- [ ] R38: 타이틀 "나의 투자 성향" + 헤더 우측 "공유" 링크. (FR-8.1)
- [ ] R39: 섹션 순서 Hero → 사주 원국 미니 → 오행 막대 → 강점 → 주의점(빨간 불릿) → 접근 참고 → 입력 정보 요약 + 수정. (FR-8.2, AC-15)
- [ ] R40: Hero "{이름}님의 투자 성향" — 10자 초과 시 8자 + "…", 빈 이름이면 "당신의 투자 성향". (FR-8.3, AC-16)
- [ ] R41: 정확도 배지 규칙: 시간·출생지·진태양시 모두 → "높음", 시간만 → "보통", 시간 미입력 → "보통 + 시간 추가 CTA(→ Step 4)". (FR-8.4, AC-17)
- [ ] R42: `hourKnown = false`이면 미니 차트 시주 칼럼 대시 테두리 + "미입력". (FR-8.5, AC-18)
- [ ] R43: 하단 "시작하기"(primary), "공유하기"(secondary) + Disclaimer("본 앱은 학습·참고용이며 투자 권유가 아닙니다" 포함). (FR-8.6, NFC-8, AC-28)
- [ ] R44: "수정" 탭 시 해당 스텝 이동(입력값 유지), 완료 시 결과로 복귀 + 재분석 자동. (FR-8.7, AC-19)
- [ ] R45: "공유하기" 탭 시 1080×1920 공유 카드 이미지 생성 후 `UIActivityViewController`. (FR-8.8, AC-20)

### Step 8.5 — 회원가입 유도
- [ ] R46: Step 8 "시작하기" 탭 시 회원가입 화면 이동. 이미 로그인된 세션은 홈으로 스킵. (FR-8.5.1, AC-21)
- [ ] R47: 타이틀 "결과 저장하기" + 설명 문구. (FR-8.5.2)
- [ ] R48: Apple / Google / 이메일 3개 가입 버튼(1차는 no-op). (FR-8.5.3)
- [ ] R49: "나중에 하기" 링크 → 비회원 상태로 홈 이동, 결과는 세션 동안 로컬 유지. (FR-8.5.4, AC-22)
- [ ] R50: "가입 시 서비스 이용약관 및 개인정보 처리방침에 동의합니다." + 링크 2개. (FR-8.5.5)

### Step 10 — 친구 초대
- [ ] R51: 홈 배너/세팅에서만 진입, WF2 플로우 종료 직후 자동 진입 금지. (FR-10.1, AC-23)
- [ ] R52: 타이틀 "친구 초대" + 헤더 우측 "내 코드: {5자리 영숫자}". (FR-10.2)
- [ ] R53: "친구 초대 혜택" 카드(가입 쿠폰 5,000원 / 친구 보상 1,000P). (FR-10.3)
- [ ] R54: 공유 카드 미리보기(ShareCard 재사용): 유형/일주·십성/오행/한 줄 설명 + "운테크.app" + 오늘 날짜. (FR-10.4, AC-24)
- [ ] R55: 공유 CTA 3개(인스타그램 스토리/링크 복사/카카오톡). (FR-10.5)
- [ ] R56: 하단 "내 초대 코드" 카드(코드 + 복사 + "초대한 친구/받은 보상" 요약). (FR-10.6)
- [ ] R57: 인스타그램 공유 URL scheme + 미설치 시 앱스토어 대체(실제 연동은 OOS, 호출 훅만). (FR-10.7)
- [ ] R58: 링크 복사 시 `https://woontech.app/invite/{CODE}`가 Pasteboard에 복사 + "복사되었어요" 토스트. (FR-10.8, AC-25)

### Non-functional
- [ ] R59: SwiftUI + 세이프 에어리어 준수 + 키보드 자동 회피. (NFC-1)
- [ ] R60: 사주 계산 <200ms + 로더 최소 1.8초 + 스텝 전환 <300ms. (NFC-2)
- [ ] R61: 진태양시 Swiss Ephemeris 기반 보정 훅(1차 스텁), 절입시는 `algorithm_of_saju.md` 따름. (NFC-3)
- [ ] R62: 모든 입력 요소 VoiceOver 레이블 + 상태 트레잇(선택/체크/값). (NFC-4, AC-26)
- [ ] R63: 뒤로/토글/체크박스/수정 버튼 hit target 44×44pt 이상. (NFC-5, AC-27)
- [ ] R64: Step 1~6 입력 메모리 유지, Step 8 렌더 시 UserDefaults(`userProfile` key)에 JSON 저장. Step 8.5 가입 완료 시 서버 업로드 훅. (NFC-6)
- [ ] R65: 모든 리터럴 `saju.*` 로컬라이즈 키로 분리(ko.lproj). (NFC-7)
- [ ] R66: Disclaimer 문구 "본 앱은 학습·참고용이며 투자 권유가 아닙니다" 포함. (NFC-8, AC-28)
- [ ] R67: 공유 카드 ImageRenderer로 1080×1920 고정 해상도 UIImage 생성. (NFC-9)

## Implementation steps

- [ ] S1: `SajuInputModel`, `SajuFlowModel`, `SajuInputStore`, `AccuracyLevel` enum, `CityCatalog` 도메인/상태 스캐폴딩(순수 Swift, TDD).
- [ ] S2: `SolarTimeCalculator.correct(longitude:standardMeridian:at:)` 구현 — 서울 127° 기준 -32분 검증 포함.
- [ ] S3: `SajuAnalysisEngine.analyze(input:)` — 결정적 스텁 결과(입력 해시 기반), 엔진 교체를 위한 인터페이스 확정.
- [ ] S4: 공용 UI 컴포넌트 — `StepProgressBarView`, `WheelPicker`, `SajuCheckbox`, `SajuSegmented`, `SajuToggleRow`.
- [ ] S5: `SajuInputFlowView` 루트 컨테이너 — 뒤로 버튼(44pt), 진행 바, 스텝 스위치, 하단 고정 CTA.
- [ ] S6: Step 1 성별 화면 구현.
- [ ] S7: Step 2 이름 화면 구현 (20자 트리밍, 공백 제외 유효성).
- [ ] S8: Step 3 생년월일 화면 구현 (양력/음력 세그먼트, 윤달 체크박스, 3-column 휠, 유효 날짜 필터).
- [ ] S9: Step 4 태어난 시간 화면 구현 (2-column 휠, 모르겠어요 체크박스 → 휠 비활성).
- [ ] S10: Step 5 출생지 화면 구현 (기본 도시 리스트, 검색, 국외 경도 입력 −180~180).
- [ ] S11: 스킵 규칙 — Step 5 → Step 7(`hourKnown=false` 시).
- [ ] S12: Step 6 진태양시 화면 구현 (토글 기본 ON, 계산 결과 박스, bottom sheet `.presentationDetents`).
- [ ] S13: Step 7 로더 구현 (`TimelineView` 진행률 + 팁 2.5s 페이드 + 최소 1.8s `Task.sleep` 보장).
- [ ] S14: Step 8 결과 화면 구현 (Hero/사주 원국 미니/오행 막대/강점/주의/접근/입력 요약) + "수정" `flow.jump(to:)` + "공유하기" → `ShareCardRenderer` → `UIActivityViewController`.
- [ ] S15: Step 8 진입 시 `store.persist()` 1회 호출 (UserDefaults `userProfile`).
- [ ] S16: Step 8.5 회원가입 유도 화면 구현 (Apple/Google/이메일 no-op + "나중에 하기" → `.home`).
- [ ] S17: Step 10 친구 초대 화면 구현 (공유 카드 미리보기, 5자리 영숫자 초대 코드, 링크 복사 + 토스트). 홈 진입점은 이번 WF 범위 밖 → 디버그 진입만.
- [ ] S18: `RootView.Route` 갱신 (`.home` 추가, `.sajuInput` 실제 뷰로 교체) + `SajuInputPlaceholderView` 제거 + `SajuInputRoot` accessibility identifier를 Step 1 컨테이너로 이관(OnboardingUITests 회귀 방지).
- [ ] S19: Localization — 모든 리터럴을 `saju.*` 키로 `ko.lproj/Localizable.strings`에 추가.
- [ ] S20: 접근성 보강 — VoiceOver 레이블/트레잇, 휠 피커 현재값 announce, hit-target 44pt 확보.
- [ ] S21: UI 테스트 launch arg — `-resetSajuInput`, `-sajuStartStep <N>`, `-preloadedProfile <JSON>` + `WoontechApp` 반영.
- [ ] S22: 엣지 케이스 — 이름 10자 초과 말줄임, `hourKnown=false` 시 시주 대시 렌더링, 이름-only 수정 시 유형 안정(입력 해시에서 이름 제외).
- [ ] S23: `Woontech.xcodeproj/project.pbxproj` 신규 파일 등록 및 타깃 멤버십 확정.

## Tests

### Unit tests (파일: `WoontechTests/...`)
- [ ] T1 (unit) `test_flow_step1_startsAtOneOfSix` — FR-C1
- [ ] T2 (unit) `test_flow_progress_updatesWithStep` — FR-C1
- [ ] T3 (unit) `test_flow_back_fromStep1_triggersExit` — FR-C2
- [ ] T4 (unit) `test_flow_ctaLabel_step1to5_next_step6_startAnalysis` — FR-C3
- [ ] T5 (unit) `test_flow_isCTAEnabled_gender_requiresSelection` — FR-1.3, FR-C4
- [ ] T6 (unit) `test_flow_swipeNavigation_notExposed` — FR-C5
- [ ] T7 (unit) `test_input_name_trimming_limit20chars_activates` — FR-2.4
- [ ] T8 (unit) `test_input_birthDate_default_1990_03_15_solar` — FR-3.4
- [ ] T9 (unit) `test_input_birthDate_yearRange_1900_toCurrent` — FR-3.5
- [ ] T10 (unit) `test_input_birthDate_invalidDays_filtered` (Feb 30, Apr 31) — FR-3.6
- [ ] T11 (unit) `test_input_lunar_leapMonth_toggle_availability` — FR-3.3
- [ ] T12 (unit) `test_input_birthDate_isCTAEnabled_default` — FR-3.7, AC-4
- [ ] T13 (unit) `test_input_birthTime_hourKnownFalse_disablesPicker` — FR-4.3, FR-4.4
- [ ] T14 (unit) `test_input_birthTime_ctaEnabledWhenKnownOrUnknown` — FR-4.5
- [ ] T15 (unit) `test_flow_skipsStep6_whenHourUnknown` — FR-6.5, AC-10
- [ ] T16 (unit) `test_input_birthPlace_default_seoul_enablesCTA` — FR-5.3
- [ ] T17 (unit) `test_input_birthPlace_overseas_longitudeRange` — FR-5.5, FR-5.6
- [ ] T18 (unit) `test_cityCatalog_searchFiltersByPrefix` — FR-5.4
- [ ] T19 (unit) `test_solarTime_default_ON` — FR-6.3
- [ ] T20 (unit) `test_solarTime_calculatedValues_forSeoul` (127° → −32분) — FR-6.4, AC-11
- [ ] T21 (unit) `test_solarTime_toggleOff_outputsNotApplied` — FR-6.4, AC-11
- [ ] T22 (unit) `test_analysisEngine_minimum1_8sGuaranteed` (injected clock) — FR-7.5, AC-14
- [ ] T23 (unit) `test_analysisEngine_returnsDeterministicResult` — FR-8.2
- [ ] T24 (unit) `test_result_displayLabel_truncatesOver10chars` — FR-8.3, AC-16
- [ ] T25 (unit) `test_result_displayLabel_fallback_whenNameEmpty` — FR-8.3, AC-16
- [ ] T26 (unit) `test_result_accuracyBadge_rules` (조합 매트릭스) — FR-8.4, AC-17
- [ ] T27 (unit) `test_result_miniChart_hourUnknownColumn_isBlank` — FR-8.5, AC-18
- [ ] T28 (unit) `test_store_persist_writesUserProfileJSON` — NFC-6
- [ ] T29 (unit) `test_store_load_restoresProfile` — NFC-6
- [ ] T30 (unit) `test_referral_inviteCode_isFiveAlnumChars_stable` — FR-10.2
- [ ] T31 (unit) `test_referral_inviteURL_format` — FR-10.8, AC-25
- [ ] T32 (unit) `test_localization_allKeysPresent_inKoLProj` — NFC-7
- [ ] T33 (unit) `test_disclaimer_containsRequiredSentence` — NFC-8, AC-28

### UI tests (파일: `WoontechUITests/...`)
- [ ] T34 (ui) `test_step1_progressBar_showsOneOfSix_onEntry` — AC-1
- [ ] T35 (ui) `test_step1_cta_disabledUntilGenderSelected` — AC-2
- [ ] T36 (ui) `test_step2_name_empty_disablesCta_validLengthEnables_maxTruncates20` — AC-3
- [ ] T37 (ui) `test_step3_defaults_1990_03_15_solar_ctaEnabled` — AC-4
- [ ] T38 (ui) `test_step3_lunar_showsLeapCheckbox_yearRange_invalidDatesFiltered` — AC-5
- [ ] T39 (ui) `test_step4_wheelSelection_enablesCta` — AC-6
- [ ] T40 (ui) `test_step4_unknownCheckbox_disablesWheel_enablesCta_setsModelFlag` — AC-7
- [ ] T41 (ui) `test_step5_defaultSeoul_ctaEnabled` — AC-8
- [ ] T42 (ui) `test_step5_overseas_longitudeBounds_validation` — AC-9
- [ ] T43 (ui) `test_flow_skipsStep6_whenHourUnknown` — AC-10
- [ ] T44 (ui) `test_step6_defaultToggleOn_showsCalculatedBox_toggleOffShowsNotApplied` — AC-11
- [ ] T45 (ui) `test_step6_whatsTrueSolarTime_openAndDismissBottomSheet` — AC-12
- [ ] T46 (ui) `test_step6_startAnalysisCta_movesToLoader` — AC-13
- [ ] T47 (ui) `test_loader_showsProgress_tips_rotated_minimum1_8seconds` — AC-14
- [ ] T48 (ui) `test_result_sectionsInOrder_hero_origin_wuxing_strength_caution_approach_input` — AC-15
- [ ] T49 (ui) `test_result_heroLabel_longName_truncates_emptyFallback` — AC-16
- [ ] T50 (ui) `test_result_accuracyBadge_high_medium_mediumWithAddTimeCta` — AC-17
- [ ] T51 (ui) `test_result_hourUnknown_miniChartHourColumn_dashed` — AC-18
- [ ] T52 (ui) `test_result_editButton_returnsToStep_appliesChange_reRendersResult` — AC-19
- [ ] T53 (ui) `test_result_share_opensActivityViewController_with1080x1920Image` — AC-20
- [ ] T54 (ui) `test_result_start_movesToSignUp_whenNotLoggedIn` — AC-21
- [ ] T55 (ui) `test_signUp_laterLink_movesToHome_keepsResultInSession` — AC-22
- [ ] T56 (ui) `test_referral_notAutoEntered_afterResultFlow` — AC-23
- [ ] T57 (ui) `test_referral_displaysCodeAndPreview_matchingProfile` — AC-24
- [ ] T58 (ui) `test_referral_copyLink_putsInviteUrlOnPasteboard_showsToast` — AC-25
- [ ] T59 (ui) `test_voiceOver_labelsAndTraits_onAllInputs` — AC-26
- [ ] T60 (ui) `test_hitTargets_backButton_toggle_checkbox_editButton_atLeast44pt` — AC-27
- [ ] T61 (ui) `test_result_disclaimer_containsStudyPhrase` — AC-28
- [ ] T62 (ui) `test_onboardingComplete_landsOnSajuInputRoot` — OnboardingUITests 회귀 방지(SajuInputRoot 식별자 이관 smoke test)
