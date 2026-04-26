import SwiftUI

// MARK: - Main View

struct EventDetailView: View {
    let event: WeeklyEvent
    let provider: any EventDetailProviding
    var onShareTap: () -> Void = {}
    var onBellReminderTap: () -> Void = {}
    var onAddToCalendarTap: () -> Void = {}
    var onLearnTap: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    // Spy counters for UI tests (opacity-0 overlay)
    @State private var shareTapCount = 0
    @State private var bellReminderTapCount = 0
    @State private var addToCalendarTapCount = 0
    @State private var learnTapCount = 0

    private var content: EventDetailContent {
        provider.content(for: event.id)
    }

    private var ddayText: String {
        "D-\(abs(event.dday))"
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: NavBar
            HStack(spacing: 16) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(DesignTokens.ink)
                }
                .accessibilityIdentifier("EventDetailBackButton")

                Text("이벤트 상세")
                    .font(.headline)
                    .foregroundColor(DesignTokens.ink)
                    .accessibilityIdentifier("EventDetailTitle")

                Spacer()

                Button(action: {
                    shareTapCount += 1
                    onShareTap()
                }) {
                    Text("공유")
                        .font(.system(size: 10))
                        .foregroundColor(DesignTokens.muted)
                }
                .accessibilityIdentifier("EventDetailShareButton")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DesignTokens.bg)
            .border(DesignTokens.line3, width: 1)

            // MARK: Scroll content
            ScrollView {
                VStack(spacing: 10) {
                    titleCardSection

                    meaningSection

                    sajuRelationSection

                    if !content.investPerspectives.isEmpty {
                        investSection
                    }

                    actionButtons

                    DisclaimerView()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        // Spy counters: opacity 0, uninteractable, readable by XCUITest
        .overlay(alignment: .topLeading) {
            VStack(spacing: 0) {
                Text("\(shareTapCount)")
                    .accessibilityIdentifier("EventDetailShareTapCount")
                Text("\(bellReminderTapCount)")
                    .accessibilityIdentifier("EventDetailBellTapCount")
                Text("\(addToCalendarTapCount)")
                    .accessibilityIdentifier("EventDetailCalendarTapCount")
                Text("\(learnTapCount)")
                    .accessibilityIdentifier("EventDetailLearnTapCount")
            }
            .opacity(0)
            .allowsHitTesting(false)
        }
    }

    // MARK: - Title Card Section

    private var titleCardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon + title + oneLiner row
            HStack(alignment: .top, spacing: 8) {
                Text(event.icon)
                    .font(.system(size: 24))
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(DesignTokens.ink)
                    Text(event.oneLiner)
                        .font(.system(size: 9))
                        .foregroundColor(DesignTokens.muted)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Date + D-day + badge gray box
            HStack {
                HStack(spacing: 0) {
                    Text(event.ddayDate)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(DesignTokens.ink)
                    Text(" — \(ddayText)")
                        .font(.system(size: 10))
                        .foregroundColor(DesignTokens.muted)
                }

                Spacer()

                if let badge = event.badge {
                    Text(badge)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(DesignTokens.ink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DesignTokens.ink, lineWidth: 1)
                        )
                        .accessibilityIdentifier("EventDetailBadgePill")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(DesignTokens.gray)
            .cornerRadius(5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("EventDetailTitleCard")
    }

    // MARK: - Meaning Section

    private var meaningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이 이벤트가 의미하는 것")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(DesignTokens.ink)
            Text(content.meaning)
                .font(.system(size: 10))
                .foregroundColor(DesignTokens.muted)
                .lineSpacing(3.0)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("EventDetailMeaningText")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("EventDetailMeaningSection")
    }

    // MARK: - Saju Relation Section

    private var sajuRelationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("내 사주와의 관계")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(DesignTokens.ink)

            VStack(alignment: .leading, spacing: 4) {
                Text(content.sajuRelationFormula)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(DesignTokens.ink)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("EventDetailSajuFormula")

                Text(content.sajuRelationNote)
                    .font(.caption)
                    .foregroundColor(DesignTokens.muted)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("EventDetailSajuNote")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(DesignTokens.gray)
            .cornerRadius(5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("EventDetailSajuSection")
    }

    // MARK: - Invest Perspectives Section

    private var investSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("💹 투자 관점")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(DesignTokens.ink)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(content.investPerspectives.enumerated()), id: \.offset) { index, perspective in
                    HStack(alignment: .top, spacing: 6) {
                        Circle()
                            .fill(DesignTokens.ink)
                            .frame(width: 4, height: 4)
                            .padding(.top, 4)
                            .accessibilityHidden(true)

                        Text(perspective)
                            .font(.system(size: 10))
                            .foregroundColor(DesignTokens.muted)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityIdentifier("EventDetailInvestBullet_\(index)")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("EventDetailInvestSection")
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 6) {
            // Bell reminder
            Button(action: {
                bellReminderTapCount += 1
                onBellReminderTap()
            }) {
                Text("🔔 D-7 푸시 알림 받기")
                    .font(.system(size: 11))
                    .foregroundColor(DesignTokens.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .contentShape(Rectangle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(DesignTokens.line2, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("EventDetailBellButton")

            // Calendar
            Button(action: {
                addToCalendarTapCount += 1
                onAddToCalendarTap()
            }) {
                Text("📅 캘린더에 추가")
                    .font(.system(size: 11))
                    .foregroundColor(DesignTokens.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .contentShape(Rectangle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(DesignTokens.line2, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("EventDetailCalendarButton")

            // Learn CTA (primary style)
            Button(action: {
                learnTapCount += 1
                onLearnTap()
            }) {
                Text(content.learnCTAText)
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(DesignTokens.ink)
                    .cornerRadius(7)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("EventDetailLearnButton")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("EventDetailActionButtons")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EventDetailView(
            event: MockWeeklyEventsProvider().events()[0],
            provider: MockEventDetailProvider()
        )
    }
}
