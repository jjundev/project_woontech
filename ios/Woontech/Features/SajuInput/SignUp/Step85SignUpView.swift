import SwiftUI

/// Step 8.5 — 결과 저장하기 회원가입 유도. FR-8.5.x / AC-21, AC-22.
struct Step85SignUpView: View {
    @EnvironmentObject private var store: SajuInputStore
    var onLater: () -> Void
    var onSignedIn: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("saju.signup.title", bundle: .main)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
                .accessibilityIdentifier("SajuSignUpTitle")

            Text("saju.signup.description", bundle: .main)
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.muted)
                .multilineTextAlignment(.leading)

            VStack(spacing: 10) {
                signUpButton(titleKey: "saju.signup.apple",
                             systemIcon: "applelogo",
                             identifier: "SajuSignUpApple")
                signUpButton(titleKey: "saju.signup.google",
                             systemIcon: "g.circle",
                             identifier: "SajuSignUpGoogle")
                signUpButton(titleKey: "saju.signup.email",
                             systemIcon: "envelope",
                             identifier: "SajuSignUpEmail")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("saju.signup.legal", bundle: .main)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.muted)
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Text("saju.signup.terms", bundle: .main)
                            .font(.system(size: 11))
                            .foregroundStyle(DesignTokens.ink)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("SajuSignUpTermsLink")
                    Button(action: {}) {
                        Text("saju.signup.privacy", bundle: .main)
                            .font(.system(size: 11))
                            .foregroundStyle(DesignTokens.ink)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("SajuSignUpPrivacyLink")
                }
            }

            Spacer()

            Button(action: onLater) {
                Text("saju.signup.later", bundle: .main)
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.muted)
                    .underline()
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("SajuSignUpLaterLink")
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.bg)
        .accessibilityIdentifier("SajuSignUpRoot")
    }

    @ViewBuilder
    private func signUpButton(titleKey: LocalizedStringKey,
                              systemIcon: String,
                              identifier: String) -> some View {
        Button(action: {
            // 1차 릴리스는 no-op. 실제 OAuth는 별도 스펙.
            store.setSignedInForTesting(true)
            onSignedIn()
        }) {
            HStack(spacing: 10) {
                Image(systemName: systemIcon)
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.ink)
                Text(titleKey, bundle: .main)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink)
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DesignTokens.line3, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
