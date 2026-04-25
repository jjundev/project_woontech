# Plan Feedback v1

## Problems

1. **UI test mock-injection 메커니즘이 기존 컨벤션과 불일치.**
   - 플랜은 `app.launchEnvironment["TODAY_HAPCHUNG_EMPTY"] = "1"` 형태의
     환경 변수와 `ProcessInfo.environment` 기반 분기를 새로 도입하려 하지만,
     실제 코드베이스(`WoontechApp.swift` line 39–118)는 `ProcessInfo.processInfo.arguments`
     를 파싱하여 `-mockHomeUnreadCount`, `-mockHeroScore`, `-preloadedProfile`,
     `-resetOnboarding` 등 **`-mock*`/플래그 prefix 인자 패턴**으로 통일되어 있다.
   - `InvestingAttitudeDetailUITests` 등 기존 UI 테스트도 `app.launchArguments`만 사용한다.
   - 새로운 env-var 채널을 도입하면 진입점에 두 개의 DI 분기 메커니즘이 공존하게 되어
     유지보수성이 저하된다. (Risk #7에서 플랜 본인도 충돌 검토가 필요하다고 인지.)

2. **AC-13 (provider swap → 모든 필드 반영)에 대한 UI15 정의가 모호.**
   - `HOME_TODAY_CUSTOM` 키만 도입하고 구체적으로 어떤 값이 주입되는지가 미정의.
   - U7(unit test)이 이미 사용자 정의 mock 모든 필드 반영을 검증하므로
     UI15는 U7로 대체 가능(Spec AC-13은 단위 테스트로 충족 가능 — "단위 테스트" 명시).
     UI15는 삭제하거나, 적어도 주입 mock의 구체적 필드 값을 플랜에 고정해야 함.

## Required changes

- (P1) UI 테스트 mock 주입 메커니즘을 **`launchArguments` + `-mock*` prefix**
  로 변경. 신규 키 후보:
  - `-mockTodayHapchungEmpty` (UI9)
  - `-mockTodayMottoTabooOn` (UI13)
  - `-mockTodayProviderVariant=custom` (UI15가 유지될 경우)
  - 그리고 `WoontechApp` 진입점의 기존 인자 파싱 블록(arguments 루프)에
    동일한 패턴으로 분기 추가. `HomeDependencies` 생성 시 `todayDetail`을
    교체하는 헬퍼를 둔다.
- (P2) UI15는 U7로 충족된다고 명시하고 UI 테스트 표에서 제거하거나,
  유지한다면 주입 mock 값(예: stem `戊/辰` · sipseong "정관/正官" · score `+5`)을
  플랜에 명시.
- Risk #7 문구도 "launchEnvironment" → "launchArguments" 표기 정정.

## Resolved since previous iteration

(없음 — iteration 1)

## Still outstanding from prior iterations

(없음 — iteration 1)
