import SwiftUI

/// 오행 균형 바 차트. FR-8.2.3.
struct WuxingBalanceBarView: View {
    let bars: [WuxingBar]
    let warning: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("saju.result.wuxing.title", bundle: .main)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(bars, id: \.element) { bar in
                    VStack(spacing: 4) {
                        GeometryReader { proxy in
                            VStack {
                                Spacer(minLength: 0)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(DesignTokens.ink)
                                    .frame(height: max(2, proxy.size.height * bar.value))
                            }
                        }
                        .frame(height: 64)
                        Text(bar.element.label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(DesignTokens.ink)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("\(bar.element.label) \(Int(bar.value * 100))%"))
                    .accessibilityIdentifier("SajuWuxingBar_\(bar.element.rawValue)")
                }
            }
            .frame(maxWidth: .infinity)

            Text(warning)
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.muted)
                .multilineTextAlignment(.leading)
                .accessibilityIdentifier("SajuWuxingWarning")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
        .accessibilityIdentifier("SajuWuxingBlock")
    }
}
