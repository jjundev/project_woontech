import SwiftUI

/// 주간 학습 진행 배너 카드.
struct SajuWeeklyProgressBannerView: View {
    let progress: WeeklyProgress

    // MARK: - Static Helpers (testable)

    /// `ratio`를 0.0~1.0 범위로 클램프한다.
    static func clampedRatio(_ raw: Double) -> Double {
        max(0.0, min(1.0, raw))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 상단 콘텐츠
            HStack(alignment: .center) {
                // 좌측: 텍스트 영역
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("이번 주 학습")
                            .font(.system(size: 9))
                            .foregroundStyle(DesignTokens.muted)

                        if progress.streakDays > 0 {
                            Text("🔥 연속 \(progress.streakDays)일")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(DesignTokens.gray)
                                        .overlay(
                                            Capsule().stroke(DesignTokens.line3, lineWidth: 1)
                                        )
                                )
                                .accessibilityIdentifier("SajuLearnStreakBadge")
                        }
                    }

                    Text("\(progress.completed) / \(progress.goal)강 완료")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DesignTokens.ink)
                }

                Spacer()

                // 우측: 퍼센트 placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DesignTokens.gray)
                    Text("\(Int((Self.clampedRatio(progress.ratio) * 100).rounded()))%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DesignTokens.muted)
                }
                .frame(width: 44, height: 44)
            }

            // 하단 진행률 바
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignTokens.gray2)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignTokens.ink)
                        .frame(
                            width: max(0, geo.size.width * Self.clampedRatio(progress.ratio)),
                            height: 4
                        )
                }
            }
            .frame(height: 4)
            .padding(.top, 10)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(DesignTokens.line3, lineWidth: 1)
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "이번 주 학습 진행, \(progress.completed)강 완료 중 \(progress.goal)강, 연속 \(progress.streakDays)일"
        )
        .accessibilityIdentifier("SajuLearnWeeklyBanner")
    }
}

#Preview {
    SajuWeeklyProgressBannerView(
        progress: WeeklyProgress(completed: 3, goal: 5, streakDays: 3)
    )
    .padding()
}
