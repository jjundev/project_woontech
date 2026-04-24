import SwiftUI

// Cached date formatter for Hero date label (DateFormatter creation is expensive)
private let heroDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy.MM.dd EEEE"
    f.locale = Locale(identifier: "ko_KR")
    return f
}()

/// Clamps a hero score to the 0–100 valid range.
/// Declared internal so unit tests can access it via @testable import.
func clampHeroScore(_ score: Int) -> Int {
    min(max(0, score), 100)
}

struct HeroInvestingCardView: View {
    let provider: any HeroInvestingProviding
    let userProfile: any UserProfileProviding
    let onTap: () -> Void

    private var clampedScore: Int {
        clampHeroScore(provider.score)
    }

    private var formattedDate: String {
        heroDateFormatter.string(from: provider.displayDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 날짜 라벨
            Text(formattedDate)
                .font(.caption)
                .foregroundStyle(DesignTokens.muted)
                .accessibilityIdentifier("HomeHeroDate")

            // 인사말
            Text("\(userProfile.displayName)님, 오늘의 투자 태도예요")
                .font(.subheadline)
                .accessibilityIdentifier("HomeHeroGreeting")

            // 카드 전체를 Button으로 감싸서 단일 hit-test 보장
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 12) {
                    // 투자 관점 배지 pill
                    Text("투자 관점")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DesignTokens.line3)
                        .clipShape(Capsule())

                    // 원형 지수 + /100
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(clampedScore)")
                            .font(.system(size: 48, weight: .bold))
                            .accessibilityIdentifier("HomeHeroScore")
                        Text("/100")
                            .font(.title3)
                            .foregroundStyle(DesignTokens.muted)
                    }
                    .accessibilityLabel("\(clampedScore)점")

                    // 한줄 카피
                    Text(provider.oneLiner)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("HomeHeroOneLiner")

                    HStack {
                        Spacer()
                        Text("상세 보기 ›")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.muted)
                    }
                }
                .padding(16)
                .background(DesignTokens.gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("HomeHeroCard")
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}
