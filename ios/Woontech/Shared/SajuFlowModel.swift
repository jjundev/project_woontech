import Foundation

// MARK: - Step

enum SajuStep: Int, Codable, Equatable, CaseIterable {
    case gender = 1
    case name = 2
    case birthDate = 3
    case birthTime = 4
    case birthPlace = 5
    case solarTime = 6
    case loader = 7
    case result = 8
    case signUp = 9      // Step 8.5
    case referral = 10

    /// 입력 스텝(1~6)만 true — 진행 바 및 하단 CTA 컨테이너 대상.
    var isInputStep: Bool {
        rawValue >= SajuStep.gender.rawValue && rawValue <= SajuStep.solarTime.rawValue
    }

    /// 입력 스텝의 번호(1~6). 그 외 스텝은 nil.
    var inputStepNumber: Int? {
        isInputStep ? rawValue : nil
    }

    /// Step 6(진태양시)만 CTA 라벨이 "사주 분석 시작". FR-C3.
    var ctaLabelKey: String {
        switch self {
        case .solarTime: return "saju.cta.startAnalysis"
        default: return "saju.cta.next"
        }
    }
}

// MARK: - Flow Model

/// Step 1~8.5 네비게이션 상태. `canAdvance(using:)`·`next(using:)`·`back(using:)`.
struct SajuFlowModel: Equatable {
    static let totalInputSteps = 6

    var currentStep: SajuStep = .gender

    /// Step 8 "수정" 탭 시 다시 결과로 돌아올지 여부.
    var returnToResult: Bool = false

    /// 진행률 — 입력 스텝 기준 (1/6 ~ 6/6).
    var progressFraction: Double {
        guard let n = currentStep.inputStepNumber else { return 1.0 }
        return Double(n) / Double(SajuFlowModel.totalInputSteps)
    }

    var progressLabel: String {
        let n = currentStep.inputStepNumber ?? SajuFlowModel.totalInputSteps
        return "\(n)/\(SajuFlowModel.totalInputSteps)"
    }

    /// 각 스텝의 CTA 활성화 조건.
    func isCTAEnabled(using input: SajuInputModel) -> Bool {
        switch currentStep {
        case .gender: return input.isGenderComplete
        case .name: return input.isNameComplete
        case .birthDate: return input.isBirthDateComplete
        case .birthTime: return input.isBirthTimeComplete
        case .birthPlace: return input.isBirthPlaceComplete
        case .solarTime: return true
        case .loader, .result, .signUp, .referral: return true
        }
    }

    /// 스와이프 네비게이션은 제공되지 않는다. FR-C5.
    let supportsSwipeNavigation: Bool = false

    /// 다음 스텝 결정. `birthPlace`에서 `hourKnown = false`면 Step 6 스킵 → Step 7. FR-6.5.
    mutating func advance(using input: SajuInputModel) {
        guard isCTAEnabled(using: input) else { return }
        switch currentStep {
        case .gender: currentStep = .name
        case .name: currentStep = .birthDate
        case .birthDate: currentStep = .birthTime
        case .birthTime: currentStep = .birthPlace
        case .birthPlace:
            currentStep = input.birthTime.hourKnown ? .solarTime : .loader
        case .solarTime: currentStep = .loader
        case .loader: currentStep = .result
        case .result: currentStep = .signUp
        case .signUp: currentStep = .signUp
        case .referral: currentStep = .referral
        }
    }

    /// 뒤로 이동. Step 1 뒤로는 onExit 콜백으로 처리(뷰 계층에서 감지). FR-C2.
    mutating func back(using input: SajuInputModel) -> Bool {
        switch currentStep {
        case .gender: return false // 뷰에서 onExit 실행
        case .name: currentStep = .gender
        case .birthDate: currentStep = .name
        case .birthTime: currentStep = .birthDate
        case .birthPlace: currentStep = .birthTime
        case .solarTime: currentStep = .birthPlace
        case .loader: return false // 로더 중 뒤로 제스처 무시. FR-7.6.
        case .result:
            // 결과 상태에서 뒤로는 이전 입력 스텝이 아닌 시스템 back 무시(뷰에서 hidden).
            return false
        case .signUp:
            currentStep = .result
        case .referral:
            // 홈 복귀는 뷰 레이어.
            return false
        }
        return true
    }

    /// Step 8 "수정" 액션. 해당 스텝으로 이동하되 완료 후 결과로 복귀.
    mutating func jump(to step: SajuStep) {
        returnToResult = (currentStep == .result) || returnToResult
        currentStep = step
    }

    /// 수정 스텝 완료 후 결과로 복귀.
    mutating func completeEditReturn() {
        currentStep = .result
        returnToResult = false
    }

    /// 결과에서 "시작하기" → Step 8.5. 이미 로그인된 상태는 뷰에서 홈으로 리다이렉트.
    mutating func moveToSignUp() {
        currentStep = .signUp
    }
}
