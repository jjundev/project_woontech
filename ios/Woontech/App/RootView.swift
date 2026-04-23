import SwiftUI

struct RootView: View {
    enum Route: Equatable {
        case splash
        case onboarding
        case sajuInput
    }

    @EnvironmentObject private var store: OnboardingStore
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
                SajuInputPlaceholderView()
                    .transition(.opacity)
            }
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
}
