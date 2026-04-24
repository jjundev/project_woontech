import SwiftUI

/// Step 7 — 분석 로더. FR-7.x / AC-14.
struct Step7LoaderView: View {
    @EnvironmentObject private var store: SajuInputStore
    var onComplete: () -> Void

    @State private var progress: Double = 0
    @State private var tipIndex: Int = 0
    @State private var startDate: Date = Date()

    private static let tips: [LocalizedStringKey] = [
        "saju.step7.tip1",
        "saju.step7.tip2",
        "saju.step7.tip3"
    ]

    private static let tipRotation: TimeInterval = 2.5

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animation placeholder — a pulsing circle.
            Circle()
                .fill(DesignTokens.gray)
                .frame(width: 80, height: 80)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("saju.step7.title", bundle: .main)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(DesignTokens.ink)
                    .accessibilityIdentifier("SajuLoaderTitle")
                Text(subMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.muted)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("SajuLoaderSubtitle")
            }

            VStack(spacing: 6) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(DesignTokens.gray)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(DesignTokens.ink)
                            .frame(width: proxy.size.width * progress, height: 6)
                            .animation(.easeInOut(duration: 0.2), value: progress)
                    }
                }
                .frame(height: 6)

                Text(percentLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink)
                    .accessibilityIdentifier("SajuLoaderPercent")
            }
            .padding(.horizontal, 40)

            tipCarousel
                .padding(.top, 12)

            Spacer()

            Text("saju.step7.credit", bundle: .main)
                .font(.system(size: 10))
                .foregroundStyle(DesignTokens.muted)
                .accessibilityIdentifier("SajuLoaderCredit")
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("SajuLoaderRoot")
        .onAppear {
            startLoaderAnimation()
        }
    }

    private var subMessage: String {
        String(format: String(localized: "saju.step7.sub"),
               store.input.birthDate.year,
               store.input.birthDate.month,
               store.input.birthDate.day)
    }

    private var percentLabel: String {
        String(format: "%d%%", Int((progress * 100).rounded()))
    }

    private var tipCarousel: some View {
        VStack(spacing: 8) {
            Text(Step7LoaderView.tips[tipIndex], bundle: .main)
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DesignTokens.gray)
                )
                .id(tipIndex)
                .transition(.opacity)
                .accessibilityIdentifier("SajuLoaderTip")

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i == tipIndex ? DesignTokens.ink : DesignTokens.gray2)
                        .frame(width: 6, height: 6)
                        .accessibilityIdentifier("SajuLoaderTipDot_\(i)")
                }
            }
        }
    }

    private func startLoaderAnimation() {
        startDate = Date()
        progress = 0
        tipIndex = 0
        // Progress driver using a background task that increments progress.
        Task { @MainActor in
            let steps = 90
            for i in 0..<steps {
                try? await Task.sleep(nanoseconds: 20_000_000) // 20ms * 90 = 1.8s
                progress = Double(i + 1) / Double(steps)
            }
            // Ensure we've also hit the minimum display interval.
            let elapsed = Date().timeIntervalSince(startDate)
            let remaining = SajuAnalysisEngine.minimumDisplayInterval - elapsed
            if remaining > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }
            progress = 1.0
            store.runAnalysis()
            onComplete()
        }

        // Tip rotation.
        Task { @MainActor in
            while progress < 1.0 {
                try? await Task.sleep(nanoseconds: UInt64(Step7LoaderView.tipRotation * 1_000_000_000))
                if progress < 1.0 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        tipIndex = (tipIndex + 1) % Step7LoaderView.tips.count
                    }
                }
            }
        }
    }
}
