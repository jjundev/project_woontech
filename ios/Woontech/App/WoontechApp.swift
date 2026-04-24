import SwiftUI

@main
struct WoontechApp: App {
    @StateObject private var store: OnboardingStore
    @StateObject private var sajuStore: SajuInputStore
    @StateObject private var homeDeps: HomeDependencies

    init() {
        let args = ProcessInfo.processInfo.arguments

        let overrideSeen = args.contains("-hasSeenOnboarding")
            && (args.firstIndex(of: "-hasSeenOnboarding").flatMap { idx -> String? in
                let next = idx + 1
                return next < args.count ? args[next] : nil
            } == "YES")

        let resetSeen = args.contains("-resetOnboarding")

        if resetSeen {
            UserDefaults.standard.removeObject(forKey: OnboardingStore.Keys.hasSeenOnboarding)
        }
        if overrideSeen {
            UserDefaults.standard.set(true, forKey: OnboardingStore.Keys.hasSeenOnboarding)
        }

        if args.contains("-resetSajuInput") {
            UserDefaults.standard.removeObject(forKey: SajuInputStore.Keys.userProfile)
        }

        let preloadedProfile: SajuInputModel? = {
            guard let idx = args.firstIndex(of: "-preloadedProfile"),
                  idx + 1 < args.count,
                  let data = args[idx + 1].data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(SajuInputModel.self, from: data)
        }()

        // Parse home mock launch args for UI tests
        let mockUnreadCount: Int? = {
            guard let idx = args.firstIndex(of: "-mockHomeUnreadCount"),
                  idx + 1 < args.count,
                  let count = Int(args[idx + 1]) else { return nil }
            return count
        }()

        let mockAvatarInitial: String? = {
            guard let idx = args.firstIndex(of: "-mockHomeAvatarInitial"),
                  idx + 1 < args.count else { return nil }
            return args[idx + 1]
        }()

        _store = StateObject(wrappedValue: OnboardingStore())
        _sajuStore = StateObject(wrappedValue: SajuInputStore(preload: preloadedProfile))

        // Build HomeDependencies, applying any mock overrides from launch args
        let resolvedDeps: HomeDependencies
        if mockUnreadCount != nil || mockAvatarInitial != nil {
            let userProfile: any UserProfileProviding = {
                if let initial = mockAvatarInitial {
                    return MockUserProfileProvider(displayName: "홍길동", avatarInitial: initial)
                }
                return MockUserProfileProvider()
            }()
            let notificationCenter: any NotificationCenterProviding = {
                if let count = mockUnreadCount {
                    return MockNotificationCenterProvider(unreadCount: count)
                }
                return MockNotificationCenterProvider()
            }()
            resolvedDeps = HomeDependencies(
                userProfile: userProfile,
                notificationCenter: notificationCenter
            )
        } else {
            resolvedDeps = HomeDependencies.mock
        }
        _homeDeps = StateObject(wrappedValue: resolvedDeps)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(sajuStore)
                .environmentObject(homeDeps)
                .onAppear {
                    applySajuStartStep()
                    applySignedInFlag()
                }
        }
    }

    private func applySajuStartStep() {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-sajuStartStep"),
              idx + 1 < args.count,
              let step = Int(args[idx + 1]),
              let target = SajuStep(rawValue: step) else { return }
        sajuStore.flow.currentStep = target
        // If jumping to result/referral, ensure there is a result to render.
        if target == .result || target == .referral {
            sajuStore.runAnalysis()
        }
    }

    private func applySignedInFlag() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-signedIn") {
            sajuStore.setSignedInForTesting(true)
        }
        if args.contains("-notSignedIn") {
            sajuStore.setSignedInForTesting(false)
        }
    }
}
