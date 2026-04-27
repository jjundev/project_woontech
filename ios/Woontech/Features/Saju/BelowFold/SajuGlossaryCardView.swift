import SwiftUI

/// Block D — 용어 사전 카드.
///
/// 탭은 no-op. VoiceOver hint에 "준비중" 표시.
struct SajuGlossaryCardView: View {
    let glossaryTermCount: Int

    /// 서브타이틀 — 단위 테스트에서 직접 검증한다.
    var subtitle: String {
        glossaryTermCount > 0 ? "명리학 용어 \(glossaryTermCount)개" : "명리학 용어"
    }

    private var voiceOverLabel: String {
        glossaryTermCount > 0
            ? "용어 사전, 명리학 용어 \(glossaryTermCount)개"
            : "용어 사전, 명리학 용어"
    }

    var body: some View {
        Button(action: { /* no-op */ }) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(DesignTokens.line3, lineWidth: 1)
                        .frame(width: 32, height: 32)
                    Text("A")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DesignTokens.ink)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("용어 사전")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignTokens.ink)

                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(DesignTokens.muted)
                }

                Spacer()

                Text("›")
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.muted)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(14)
            .background(DesignTokens.bg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DesignTokens.line3, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(voiceOverLabel)
        .accessibilityHint("준비중")
        .accessibilityIdentifier("SajuGlossaryCard")
    }
}

#Preview {
    VStack(spacing: 8) {
        SajuGlossaryCardView(glossaryTermCount: 120)
        SajuGlossaryCardView(glossaryTermCount: 0)
    }
    .padding()
}
