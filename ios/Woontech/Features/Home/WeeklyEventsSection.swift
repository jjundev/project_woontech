import SwiftUI

struct WeeklyEventsSection: View {
    let provider: any WeeklyEventsProviding
    let onCalendarTap: () -> Void
    let onEventTap: (WeeklyEvent) -> Void

    private let timeGroupOrder: [TimeGroup] = [.thisWeek, .thisMonth, .within3Months]

    private func eventsForTimeGroup(_ timeGroup: TimeGroup) -> [WeeklyEvent] {
        provider.events().filter { $0.timeGroup == timeGroup }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("이번 주 흐름")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DesignTokens.muted)
                        .tracking(0.3)

                    Text("다가올 절기·대운 이벤트")
                        .font(.caption2)
                        .foregroundStyle(DesignTokens.muted)
                        .padding(.top, 2)
                }

                Spacer()

                Button(action: onCalendarTap) {
                    Text("캘린더 보기 ›")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.muted)
                }
                .accessibilityIdentifier("WeeklyEventsCalendarButton")
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            // Time group sections
            VStack(alignment: .leading, spacing: 0) {
                ForEach(timeGroupOrder, id: \.self) { timeGroup in
                    let events = eventsForTimeGroup(timeGroup)
                    if !events.isEmpty {
                        // Time group divider
                        HStack(alignment: .center, spacing: 8) {
                            Text(timeGroup.displayName)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(DesignTokens.muted)

                            Divider()
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)

                        // Event cards
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(events, id: \.id) { event in
                                EventCardView(
                                    event: event,
                                    onTap: { onEventTap(event) }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .accessibilityIdentifier("WeeklyEventsSection")
    }
}

#Preview {
    WeeklyEventsSection(
        provider: MockWeeklyEventsProvider(),
        onCalendarTap: {},
        onEventTap: { _ in }
    )
}
