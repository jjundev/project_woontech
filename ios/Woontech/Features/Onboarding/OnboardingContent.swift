import SwiftUI

struct OnboardingContent {
    let titleKey: LocalizedStringKey
    let titleAccessibilityKey: String
    let bodyKey: LocalizedStringKey
    let bodyAccessibilityKey: String
    let illustrationAsset: String

    static let all: [OnboardingContent] = [
        OnboardingContent(
            titleKey: "onboarding.1.title",
            titleAccessibilityKey: "onboarding.1.title",
            bodyKey: "onboarding.1.body",
            bodyAccessibilityKey: "onboarding.1.body",
            illustrationAsset: "illustration_1"
        ),
        OnboardingContent(
            titleKey: "onboarding.2.title",
            titleAccessibilityKey: "onboarding.2.title",
            bodyKey: "onboarding.2.body",
            bodyAccessibilityKey: "onboarding.2.body",
            illustrationAsset: "illustration_2"
        ),
        OnboardingContent(
            titleKey: "onboarding.3.title",
            titleAccessibilityKey: "onboarding.3.title",
            bodyKey: "onboarding.3.body",
            bodyAccessibilityKey: "onboarding.3.body",
            illustrationAsset: "illustration_3"
        )
    ]
}
