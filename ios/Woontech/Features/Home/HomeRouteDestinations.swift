import SwiftUI

// Deprecated - replaced with actual InvestingAttitudeDetailView
@available(*, deprecated, message: "Use InvestingAttitudeDetailView instead")
struct InvestingPlaceholderView: View {
    var body: some View {
        Text("준비중")
            .accessibilityIdentifier("HomeRoute_investingDest")
    }
}

struct EventPlaceholderView: View {
    var body: some View {
        Text("준비중")
            .accessibilityIdentifier("HomeRoute_eventDest")
    }
}

struct TodayPlaceholderView: View {
    var body: some View {
        Text("준비중")
            .accessibilityIdentifier("HomeRoute_todayDest")
    }
}

struct TabooPlaceholderView: View {
    var body: some View {
        Text("준비중")
            .accessibilityIdentifier("HomeRoute_tabooDest")
    }
}

struct PracticePlaceholderView: View {
    var body: some View {
        Text("준비중")
            .accessibilityIdentifier("HomeRoute_practiceDest")
    }
}
