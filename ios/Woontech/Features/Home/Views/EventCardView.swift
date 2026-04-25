import SwiftUI

struct EventCardView: View {
    let event: WeeklyEvent
    let onTap: () -> Void

    private var isNegative: Bool {
        event.impact == .negative
    }

    private var showBadge: Bool {
        event.impact == .positive && event.badge != nil
    }

    private var ddayText: String {
        let absValue = abs(event.dday)
        return "D-\(absValue)"
    }

    private var negativeColor: Color {
        DesignTokens.fireColor
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 0) {
                // Left accent bar for negative impact
                if isNegative {
                    Rectangle()
                        .fill(negativeColor)
                        .frame(width: 3)
                }

                // Main content
                VStack(alignment: .leading, spacing: 0) {
                    // Top row: icon + title + badge + D-day
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        // Icon
                        Text(event.icon)
                            .font(.system(size: 16))
                            .lineLimit(1)

                        // Title and badge
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .center, spacing: 5) {
                                Text(event.title)
                                    .font(.system(size: 11, weight: .bold))
                                    .lineLimit(1)

                                if showBadge, let badge = event.badge {
                                    Text(badge)
                                        .font(.system(size: 7, weight: .bold))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .border(DesignTokens.ink, width: 1)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }

                            Text(event.oneLiner)
                                .font(.caption)
                                .foregroundStyle(DesignTokens.muted)
                                .lineLimit(1)
                                .padding(.top, 2)
                        }

                        Spacer()

                        // D-day badge (right side)
                        Text(ddayText)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(isNegative ? negativeColor : DesignTokens.muted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .border(isNegative ? negativeColor : DesignTokens.line3, width: 1)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Date text
                    Text(event.ddayDate)
                        .font(.system(size: 8))
                        .foregroundStyle(DesignTokens.muted)
                        .padding(.top, 4)

                    // Invest context box
                    HStack(alignment: .center, spacing: 6) {
                        Text("💹 \(event.investContext)")
                            .font(.system(size: 9))
                            .foregroundStyle(DesignTokens.muted)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        Text("알림 ›")
                            .font(.system(size: 8))
                            .foregroundStyle(DesignTokens.muted)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(DesignTokens.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(.top, 6)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .background(Color.white)
            .border(isNegative ? negativeColor : DesignTokens.line2, width: 1)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("EventCard_\(event.id)")
    }
}

#Preview {
    VStack(spacing: 12) {
        // Positive event with badge
        EventCardView(
            event: WeeklyEvent(
                type: .daewoon,
                icon: "🔄",
                title: "대운 전환",
                hanja: "大運",
                dday: -89,
                ddayDate: "2026.05.12",
                impact: .positive,
                oneLiner: "새로운 10년 주기 — 병진 대운 진입",
                investContext: "안정형 → 도전형 전환 신호 · 새 자산군 탐색 참고 시기",
                badge: "중요",
                timeGroup: .within3Months
            ),
            onTap: {}
        )

        // Negative event
        EventCardView(
            event: WeeklyEvent(
                type: .hapchung,
                icon: "⚠",
                title: "월지충 · 卯↔酉",
                hanja: nil,
                dday: -4,
                ddayDate: "4/27 월",
                impact: .negative,
                oneLiner: "직업궁 충돌 — 부서 이동·갈등 주의",
                investContext: "충동적 결정 주의 · 관망 참고",
                badge: nil,
                timeGroup: .thisWeek
            ),
            onTap: {}
        )
    }
    .padding()
}
