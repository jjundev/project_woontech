import SwiftUI

/// Block A — 사주 공부하기 섹션 헤더.
///
/// 좌측: "사주 공부하기" 타이틀 + 연속 학습 배지(streakDays > 0 일 때만).
/// 우측: "전체 ›" 버튼 → onAllTap 콜백.
struct SajuStudySectionHeaderView: View {
    let streakDays: Int
    let onAllTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("사주 공부하기")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(DesignTokens.ink)

            if streakDays > 0 {
                Text("🔥 연속 \(streakDays)일")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DesignTokens.ink)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(DesignTokens.gray)
                    .overlay(
                        Capsule().stroke(DesignTokens.line3, lineWidth: 1)
                    )
                    .clipShape(Capsule())
                    .accessibilityLabel("연속 학습 \(streakDays)일")
                    .accessibilityIdentifier("SajuStreakBadge")
            }

            Spacer()

            Button(action: onAllTap) {
                Text("전체 ›")
                    .font(.system(size: 10))
                    .foregroundStyle(DesignTokens.muted)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("SajuStudyAllButton")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("SajuStudySectionHeader")
    }
}

#Preview {
    VStack(spacing: 16) {
        SajuStudySectionHeaderView(streakDays: 3, onAllTap: {})
        SajuStudySectionHeaderView(streakDays: 0, onAllTap: {})
    }
    .padding()
}
