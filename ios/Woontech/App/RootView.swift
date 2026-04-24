import SwiftUI

struct RootView: View {
    enum Route: Equatable {
        case splash
        case onboarding
        case sajuInput
        case home
        case referral
    }

    @EnvironmentObject private var store: OnboardingStore
    @EnvironmentObject private var sajuStore: SajuInputStore
    @State private var route: Route = .splash

    var body: some View {
        ZStack {
            DesignTokens.bg.ignoresSafeArea()

            switch route {
            case .splash:
                SplashView(onFinish: handleSplashFinish)
                    .transition(.opacity)
            case .onboarding:
                OnboardingView(onComplete: handleOnboardingComplete)
                    .transition(.opacity)
            case .sajuInput:
                SajuInputFlowView(
                    onExit: { withAnimation { route = .onboarding } },
                    onFinish: { withAnimation { route = .home } },
                    onOpenReferral: { withAnimation { route = .referral } }
                )
                .environmentObject(sajuStore)
                .transition(.opacity)
            case .home:
                HomePlaceholderView(
                    onOpenReferral: { withAnimation { route = .referral } }
                )
                .environmentObject(sajuStore)
                .transition(.opacity)
            case .referral:
                Step10ReferralView(onBack: {
                    withAnimation { route = .home }
                })
                .environmentObject(sajuStore)
                .transition(.opacity)
            }
        }
        .onAppear {
            applyLaunchArgs()
        }
    }

    private func handleSplashFinish() {
        withAnimation(.easeInOut(duration: 0.25)) {
            route = store.hasSeenOnboarding ? .sajuInput : .onboarding
        }
    }

    private func handleOnboardingComplete() {
        store.markSeen()
        withAnimation(.easeInOut(duration: 0.25)) {
            route = .sajuInput
        }
    }

    private func applyLaunchArgs() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-openReferral") {
            // Allow UI tests to land directly on referral.
            route = .referral
        } else if args.contains("-openHome") {
            route = .home
        }
    }
}
