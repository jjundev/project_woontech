import Foundation

struct OnboardingFlowModel: Equatable {
    static let totalSteps = 3

    var step: Int = 1
    var disclaimerChecked: Bool = false

    var ctaLabelKey: String {
        step == OnboardingFlowModel.totalSteps ? "onboarding.cta.start" : "onboarding.cta.next"
    }

    var isCTAEnabled: Bool {
        if step == OnboardingFlowModel.totalSteps {
            return disclaimerChecked
        }
        return true
    }

    var isLastStep: Bool { step == OnboardingFlowModel.totalSteps }
    var isFirstStep: Bool { step == 1 }

    mutating func goNext() {
        guard step < OnboardingFlowModel.totalSteps else { return }
        step += 1
    }

    mutating func goPrevious() {
        guard step > 1 else { return }
        step -= 1
    }

    mutating func jump(to target: Int) {
        guard (1...OnboardingFlowModel.totalSteps).contains(target) else { return }
        step = target
    }

    mutating func toggleDisclaimer() {
        disclaimerChecked.toggle()
    }
}
