import SwiftUI

/// WF3 자리표시자. WF2 종료 후 "나중에 하기" 또는 가입 완료의 착지점.
struct HomePlaceholderView: View {
    @EnvironmentObject private var sajuStore: SajuInputStore
    var onOpenReferral: () -> Void = {}

    var body: some View {
        ZStack {
            DesignTokens.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("saju.home.title", bundle: .main)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(DesignTokens.ink)
                Text("saju.home.body", bundle: .main)
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.muted)
                    .multilineTextAlignment(.center)

                Button(action: onOpenReferral) {
                    Text("saju.home.referral", bundle: .main)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DesignTokens.ink)
                        .underline()
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("HomeOpenReferralLink")
            }
            .padding(24)
        }
        .accessibilityIdentifier("HomeRoot")
    }
}
