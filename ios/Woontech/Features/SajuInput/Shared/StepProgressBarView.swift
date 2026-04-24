import SwiftUI

/// 진행 바 — 1/6 ~ 6/6. FR-C1 / AC-1.
struct StepProgressBarView: View {
    let current: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(current)/\(total)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DesignTokens.muted)
                    .accessibilityIdentifier("SajuProgressLabel")
                Spacer()
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignTokens.gray)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignTokens.ink)
                        .frame(width: proxy.size.width * fraction, height: 4)
                        .animation(.easeInOut(duration: 0.2), value: fraction)
                }
            }
            .frame(height: 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("진행 \(current) / \(total)"))
        .accessibilityIdentifier("SajuProgressBar")
    }

    private var fraction: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(current) / CGFloat(total)
    }
}
