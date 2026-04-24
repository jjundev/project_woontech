import SwiftUI

/// Step 8.5 — 회원가입 유도 (결과 후). FR-8.5.x / AC-21, AC-22.
struct Step85SignUpView: View {
    @EnvironmentObject private var store: SajuInputStore
    var onLater: () -> Void
    var onSignedIn: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header — back + "시작하기"
            ZStack {
                HStack {
                    Button(action: { store.back() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DesignTokens.ink)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("SajuSignUpBackButton")
                    Spacer()
                }
                Text("saju.signup.header", bundle: .main)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink)
            }
            .padding(.horizontal, 16)

            Rectangle()
                .fill(DesignTokens.line3)
                .frame(height: 1)

            VStack(spacing: 0) {
                Spacer()

                // Logo + title + buttons (centered)
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(DesignTokens.muted, lineWidth: 1)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Text("LOGO")
                                .font(.system(size: 10))
                                .foregroundStyle(DesignTokens.muted)
                        )

                    Text("saju.signup.title", bundle: .main)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(DesignTokens.ink)
                        .padding(.top, 14)

                    Text("saju.signup.description", bundle: .main)
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.muted)
                        .padding(.top, 6)

                    // Sign up buttons
                    VStack(spacing: 10) {
                        signUpButton(
                            titleKey: "saju.signup.kakao",
                            isPrimary: true,
                            iconCornerRadius: 3,
                            identifier: "SajuSignUpKakao"
                        )
                        signUpButton(
                            titleKey: "saju.signup.google",
                            isPrimary: false,
                            iconCornerRadius: 9,
                            identifier: "SajuSignUpGoogle"
                        )
                        signUpButton(
                            titleKey: "saju.signup.email",
                            isPrimary: false,
                            iconCornerRadius: 9,
                            identifier: "SajuSignUpEmail"
                        )
                    }
                    .padding(.top, 28)
                }
                .frame(maxWidth: .infinity)

                Spacer()

                // Guest option
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(DesignTokens.line3)
                        .frame(height: 1)

                    Button(action: onLater) {
                        Text("saju.signup.guest", bundle: .main)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(DesignTokens.muted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("SajuSignUpGuestLink")

                    Text("saju.signup.guest.note", bundle: .main)
                        .font(.system(size: 9))
                        .foregroundStyle(DesignTokens.muted)
                }

                // Legal
                Text("saju.signup.legal", bundle: .main)
                    .font(.system(size: 9))
                    .foregroundStyle(DesignTokens.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(DesignTokens.bg)
        .accessibilityIdentifier("SajuSignUpRoot")
    }

    @ViewBuilder
    private func signUpButton(titleKey: LocalizedStringKey,
                              isPrimary: Bool,
                              iconCornerRadius: CGFloat,
                              identifier: String) -> some View {
        Button(action: {
            // 1차 릴리스는 no-op. 실제 OAuth는 별도 스펙.
            store.setSignedInForTesting(true)
            onSignedIn()
        }) {
            ZStack {
                HStack {
                    RoundedRectangle(cornerRadius: iconCornerRadius)
                        .stroke(isPrimary ? Color.white : DesignTokens.muted, lineWidth: 1.2)
                        .frame(width: 18, height: 18)
                        .padding(.leading, 14)
                    Spacer()
                }
                Text(titleKey, bundle: .main)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isPrimary ? .white : DesignTokens.ink)
            }
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isPrimary ? DesignTokens.ink : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(DesignTokens.ink, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
