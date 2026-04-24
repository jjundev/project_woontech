import SwiftUI

@main
struct WoontechApp: App {
    @StateObject private var store: OnboardingStore
    @StateObject private var sajuStore: SajuInputStore

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

        _store = StateObject(wrappedValue: OnboardingStore())
        _sajuStore = StateObject(wrappedValue: SajuInputStore(preload: preloadedProfile))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(sajuStore)
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
