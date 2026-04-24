import SwiftUI

/// WF2 루트 컨테이너 — 뒤로 버튼, 진행 바, 스텝 스위치, 하단 고정 CTA.
/// FR-C1 / FR-C2 / FR-C3 / FR-C5.
struct SajuInputFlowView: View {
    @EnvironmentObject private var store: SajuInputStore
    var onExit: () -> Void
    var onFinish: () -> Void
    var onOpenReferral: () -> Void = {}

    var body: some View {
        ZStack {
            DesignTokens.bg.ignoresSafeArea()

            switch store.flow.currentStep {
            case .gender, .name, .birthDate, .birthTime, .birthPlace, .solarTime:
                inputStepContainer
            case .loader:
                Step7LoaderView(onComplete: {
                    store.flow.currentStep = .result
                })
                .environmentObject(store)
            case .result:
                Step8ResultView(onStart: {
                    if store.isSignedIn {
                        onFinish()
                    } else {
                        store.advance()
                    }
                })
                .environmentObject(store)
            case .signUp:
                Step85SignUpView(
                    onLater: { onFinish() },
                    onSignedIn: { onFinish() }
                )
                .environmentObject(store)
            case .referral:
                Step10ReferralView(onBack: onFinish)
                    .environmentObject(store)
            }
        }
        .onChange(of: store.flow.currentStep) { _, _ in
            // Re-analysis on (re)entry is handled in the view's onAppear.
        }
    }

    private var inputStepContainer: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                stepContent
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }
            Spacer(minLength: 0)
            bottomCTA
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier(store.flow.currentStep == .gender
                                  ? "SajuInputRoot"
                                  : "SajuInputStep_\(store.flow.currentStep.rawValue)")
    }

    private var topBar: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: handleBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DesignTokens.ink)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("SajuBackButton")
                .accessibilityLabel(Text("saju.back", bundle: .main))
                Spacer()
            }
            .padding(.horizontal, 8)

            if let stepNumber = store.flow.currentStep.inputStepNumber {
                StepProgressBarView(
                    current: stepNumber,
                    total: SajuFlowModel.totalInputSteps
                )
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch store.flow.currentStep {
        case .gender:     Step1GenderView().environmentObject(store)
        case .name:       Step2NameView().environmentObject(store)
        case .birthDate:  Step3BirthDateView().environmentObject(store)
        case .birthTime:  Step4BirthTimeView().environmentObject(store)
        case .birthPlace: Step5BirthPlaceView().environmentObject(store)
        case .solarTime:  Step6SolarTimeView().environmentObject(store)
        default: EmptyView()
        }
    }

    private var bottomCTA: some View {
        VStack {
            PrimaryButton(
                titleKey: LocalizedStringKey(store.flow.currentStep.ctaLabelKey),
                isEnabled: store.flow.isCTAEnabled(using: store.input),
                action: handleCTA
            )
            .accessibilityIdentifier("SajuCTA")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(DesignTokens.bg.ignoresSafeArea(edges: .bottom))
    }

    private func handleBack() {
        let moved = store.back()
        if !moved, store.flow.currentStep == .gender {
            onExit()
        }
    }

    private func handleCTA() {
        if store.flow.returnToResult,
           store.flow.currentStep != .result,
           store.flow.currentStep.isInputStep {
            store.finishEditReturnToResult()
            return
        }
        store.advance()
    }
}
