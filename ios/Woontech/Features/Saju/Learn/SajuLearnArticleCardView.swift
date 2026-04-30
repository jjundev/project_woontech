import SwiftUI

/// 추천 아티클 카드.
struct SajuLearnArticleCardView: View {
    let article: Article
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // 좌측: placeholder 44×44
                RoundedRectangle(cornerRadius: 6)
                    .fill(DesignTokens.gray)
                    .frame(width: 44, height: 44)

                // 우측: 타이틀 + 메타
                VStack(alignment: .leading, spacing: 2) {
                    Text(article.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DesignTokens.ink)
                        .multilineTextAlignment(.leading)

                    Text(article.metaLabel)
                        .font(.system(size: 9))
                        .foregroundStyle(DesignTokens.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .background(DesignTokens.bg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DesignTokens.line3, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("준비중")
        .accessibilityIdentifier("SajuLearnArticleCard_\(article.id)")
    }
}

#Preview {
    SajuLearnArticleCardView(
        article: Article(
            id: "A1",
            title: "내 사주 일간이 丙(병)이면 어떤 사람?",
            metaLabel: "읽기 · 4분"
        ),
        onTap: {}
    )
    .padding()
}
