import SwiftUI

/// 카테고리 카드 1개.
///
/// `summary`가 nil이면 "데이터 없음" placeholder를 표시한다.
/// 카드 전체(좌측 텍스트 + 우측 chevron/"근거 보기" 포함)가 단일 `Button`으로
/// 감싸여 있으므로 "근거 보기" 영역도 카드 전체 탭과 동일한 동작을 한다.
struct SajuCategoryCardView: View {
    let summary: SajuCategorySummary?
    let kind: SajuCategorySummary.Kind
    let onTap: () -> Void

    var body: some View {
        if let summary {
            Button(action: onTap) {
                HStack(alignment: .center, spacing: 10) {
                    // 좌측 텍스트 영역
                    VStack(alignment: .leading, spacing: 4) {
                        Text(summary.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DesignTokens.ink)

                        Text(summary.summary)
                            .font(.system(size: 13))
                            .foregroundStyle(DesignTokens.muted)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)

                        if let badge = summary.badge {
                            Text(badge)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(DesignTokens.ink)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(DesignTokens.gray2)
                                .cornerRadius(10)
                                .accessibilityIdentifier("SajuCategoryBadge_\(kind.rawValue)")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // 우측 chevron / 근거 보기
                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundStyle(DesignTokens.muted)

                        Text("근거 보기")
                            .font(.system(size: 11))
                            .foregroundStyle(DesignTokens.muted)
                            .underline()
                            .accessibilityIdentifier("SajuCategoryEvidence_\(kind.rawValue)")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(DesignTokens.bg)
            .accessibilityLabel(accessibilityLabel(for: summary))
            .accessibilityIdentifier("SajuCategoryCard_\(kind.rawValue)")
        } else {
            // Placeholder when no data
            HStack {
                Text("데이터 없음")
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.muted)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(DesignTokens.bg)
            .accessibilityIdentifier("SajuCategoryCard_\(kind.rawValue)")
        }
    }

    private func accessibilityLabel(for summary: SajuCategorySummary) -> String {
        var label = "\(summary.title), \(summary.summary)"
        if let badge = summary.badge {
            label += ", \(badge) 표시"
        }
        return label
    }
}
