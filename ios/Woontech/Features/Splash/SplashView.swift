import SwiftUI

struct SplashView: View {
    let onFinish: () -> Void

    static let duration: Duration = .milliseconds(1500)

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image("logo")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(DesignTokens.line2)
                .overlay(
                    Rectangle()
                        .stroke(DesignTokens.line2, lineWidth: 1)
                )
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text("splash.title", bundle: .main)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(DesignTokens.ink)
                Text("splash.subtitle", bundle: .main)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.muted)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("SplashTitleBlock")

            Spacer()

            ProgressView()
                .progressViewStyle(.circular)
                .tint(DesignTokens.ink)
                .frame(width: 24, height: 24)
                .padding(.bottom, 40)
                .accessibilityIdentifier("SplashSpinner")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(DesignTokens.bg)
        .accessibilityIdentifier("SplashRoot")
        .task {
            do {
                try await Task.sleep(for: SplashView.duration)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            onFinish()
        }
    }
}
