import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var flow = OnboardingFlowModel()

    var body: some View {
        VStack(spacing: 0) {
            skipRow
                .padding(.horizontal, 20)
                .padding(.top, 20)

            TabView(selection: selectionBinding) {
                ForEach(1...OnboardingFlowModel.totalSteps, id: \.self) { step in
                    OnboardingStepView(step: step)
                        .tag(step)
                        .padding(.horizontal, 20)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.25), value: flow.step)

            PageIndicatorView(
                current: flow.step,
                total: OnboardingFlowModel.totalSteps,
                onTap: handleIndicatorTap
            )
            .padding(.bottom, 4)

            if flow.isLastStep {
                DisclaimerCheckboxView(checked: disclaimerBinding)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)
            }

            PrimaryButton(
                titleKey: primaryCTAKey,
                isEnabled: flow.isCTAEnabled,
                action: handleCTATap
            )
            .padding(.horizontal, 20)
            .accessibilityIdentifier("OnboardingCTA")

            if flow.isLastStep {
                Text("onboarding.disclaimer.footer", bundle: .main)
                    .font(.system(size: 8))
                    .foregroundStyle(DesignTokens.muted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, 20)
                    .accessibilityIdentifier("OnboardingDisclaimerFooter")
            }

            Spacer(minLength: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.bg)
        .accessibilityIdentifier("OnboardingRoot")
    }

    // MARK: - Sub-views

    private var skipRow: some View {
        HStack {
            Spacer()
            Button(action: handleSkipTap) {
                Text("onboarding.skip", bundle: .main)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.muted)
                    .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("onboarding.skip", bundle: .main))
            .accessibilityIdentifier("OnboardingSkipButton")
        }
    }

    // MARK: - Bindings

    private var selectionBinding: Binding<Int> {
        Binding(
            get: { flow.step },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.25)) {
                    flow.jump(to: newValue)
                }
            }
        )
    }

    private var disclaimerBinding: Binding<Bool> {
        Binding(
            get: { flow.disclaimerChecked },
            set: { flow.disclaimerChecked = $0 }
        )
    }

    private var primaryCTAKey: LocalizedStringKey {
        flow.isLastStep ? "onboarding.cta.start" : "onboarding.cta.next"
    }

    // MARK: - Actions

    private func handleCTATap() {
        guard flow.isCTAEnabled else { return }
        if flow.isLastStep {
            onComplete()
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                flow.goNext()
            }
        }
    }

    private func handleSkipTap() {
        onComplete()
    }

    private func handleIndicatorTap(_ target: Int) {
        withAnimation(.easeInOut(duration: 0.25)) {
            flow.jump(to: target)
        }
    }
}
