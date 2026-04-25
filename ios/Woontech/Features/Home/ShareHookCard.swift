import SwiftUI

struct ShareHookCard: View {
    let onSharePreviewTap: () -> Void
    let onShareTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card content
            VStack(alignment: .leading, spacing: 10) {
                // Header with icon
                HStack(alignment: .top, spacing: 10) {
                    Text("💌")
                        .font(.system(size: 18))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("내 사주 카드로 친구 초대")
                            .font(.system(size: 11, weight: .bold))

                        Text("둘 다 PRO 1개월 무료")
                            .font(.caption2)
                            .foregroundStyle(DesignTokens.muted)
                    }
                }

                // Buttons
                HStack(alignment: .center, spacing: 6) {
                    Button(action: onSharePreviewTap) {
                        Text("카드 미리보기")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(DesignTokens.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .background(Color(.systemBackground))
                            .border(DesignTokens.line2, width: 1)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .accessibilityIdentifier("ShareHookCardPreviewButton")

                    Button(action: onShareTap) {
                        Text("공유하기")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .background(DesignTokens.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .accessibilityIdentifier("ShareHookCardShareButton")
                }
            }
            .padding(12)
            .background(DesignTokens.gray)
            .border(DesignTokens.line3, width: 1)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .accessibilityIdentifier("ShareHookCard")
    }
}

#Preview {
    ShareHookCard(
        onSharePreviewTap: {},
        onShareTap: {}
    )
}
