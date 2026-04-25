import SwiftUI

struct DisclaimerView: View {
    var body: some View {
        Text("본 앱은 학습·참고용이며 투자 권유가 아닙니다. 투자 결정은 본인 판단과 책임 하에 이루어져야 합니다.")
            .font(.caption2)
            .foregroundStyle(DesignTokens.muted)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .accessibilityIdentifier("DisclaimerText")
    }
}

#Preview {
    DisclaimerView()
        .padding()
        .background(DesignTokens.gray)
}
