## WF4-01 — 사주 탭 Shell + NavigationStack + DI 스캐폴드

WF3 홈 탭과 동일한 위계로 동작하는 **사주 탭(TabBar index 2)** 의 기반 구조를 구축합니다.
이후 슬라이스(WF4-02~07)가 올라탈 `SajuTabView` 컨테이너, 사주 탭 전용 NavigationStack,
타입 안전한 라우트 enum, DI 컨테이너(프로토콜 6종 + Mock 구현체), 상단 헤더(타이틀 "사주" + 우측 placeholder 아이콘)를 하나의 테스트 가능한 단위로 묶습니다.

## Summary

- `MainTabContainerView` 도입: 4탭 TabView(홈/투자/사주/마이), 런치 인자 `-openSajuTab` 으로 사주 탭 바로 진입 지원
- `SajuTabView`: Header + 1px Divider + NavigationStack(path: $path) + "준비중" placeholder 컨텐츠
- `SajuRoute` enum 7케이스 (`elements`, `tenGods`, `learn`, `lesson(id:)`, `daewoonPlaceholder`, `hapchungPlaceholder`, `yongsinPlaceholder`) + `Hashable`
- DI 프로토콜 6종 + `MockXxx` 구현체 + `SajuTabDependencies` ObservableObject
- `AppLaunchContractUITests` 확장: `-openSajuTab` 런치 계약 검증
- `InvestingAttitudeDetailView` 접근성 픽스: `.accessibilityElement(children: .contain)` 추가 (iOS 26 TabView-nested NavigationStack identifier flattening 방지)

## Implementation Checklist

### Requirements
- [x] R1: Main TabBar에 사주 탭(index 2) 추가, 탭 셀렉트 시 `SajuTabView` 렌더, 다른 탭(홈/투자/마이) 동작 변경 없음
- [x] R2: `SajuTabView` = 상단 고정 Header + 컨텐츠 슬롯(빈 ScrollView + "준비중") + 하단 공통 TabBar(active=2)
- [x] R3: `SajuTabView` 내부에 사주 탭 전용 NavigationStack — 홈 탭 NavigationStack과 인스턴스 분리
- [x] R4: `SajuRoute` enum 7 케이스 컴파일 + `Hashable`
- [x] R5: 각 `SajuRoute` 케이스에 대응하는 placeholder 목적지 View 존재. `lesson(id:)`는 식별자 화면 표시
- [x] R6: DI 프로토콜 6종 + 각 `MockXxx` 구현체 + 와이어프레임 기본값
- [x] R7: `SajuTabDependencies` 단일 ObservableObject로 6 providing 필드 묶어 주입, 테스트 시 mock 교체 가능
- [x] R8: 런치 인자 `-openSajuTab` 처리 — 부팅 직후 TabBar index 2가 활성 상태
- [x] R9: iOS 17+ SwiftUI NavigationStack, safe area 준수
- [x] R10: `DesignTokens.swift` 색/간격/타이포 재사용. 신규 토큰 없음
- [x] R11: VoiceOver — Header 타이틀 "사주", 우측 아이콘 "사주 메뉴", TabBar 사주 셀 "사주 탭"
- [x] R12: Dynamic Type XL에서 Header/TabBar 잘림·겹침 없음
- [x] R13: 모든 텍스트 리터럴 로컬라이즈 키로 분리
- [x] R14: 탭 전환 시 사주 탭 NavigationStack path 보존

### Implementation Steps
- [x] S1–S13 모두 완료 (모델 / 프로토콜 / 의존성 구조체 / 헤더 뷰 / 컨텐츠 placeholder / 라우트 목적지 / SajuTabView / MainTabContainerView / WoontechApp + RootView 배선 / HomeDashboardView 정리 / 로컬라이즈 키 / pbxproj 등록)

### Tests
- [x] T1–T12 (unit): 12/12 PASSED
- [x] T13–T29 (UI): 21/21 PASSED (AppLaunchContractUITests 4/4 포함)

## Test Results

- **Unit tests**: `"result": "Passed"` — passedTests: 12, failedTests: 0
- **UI tests**: `"result": "Passed"` — passedTests: 21, failedTests: 0

See `implement-review.md` for full build/test evidence.

## Notable Fix (ui_verify phase)

`T29 test_homeAndSajuStacks_isolated` — iOS 26에서 `InvestingAttitudeDetailView`가 TabView-nested NavigationStack으로 push될 때, outer VStack의 `.accessibilityIdentifier("InvestingAttitudeDetailView")`가 자식 요소들에 전파되어 `InvestingAttitudeDetailTitle` StaticText 쿼리가 실패했습니다. `.accessibilityElement(children: .contain)` 추가로 수정했습니다. 자세한 내용은 `implement-feedback-version-2.md` 참조.
