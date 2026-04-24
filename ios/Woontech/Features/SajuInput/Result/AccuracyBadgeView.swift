import SwiftUI

/// 정확도 배지. FR-8.4 / AC-17.
struct AccuracyBadgeView: View {
    let accuracy: AccuracyLevel
    var onAddTime: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(DesignTokens.gray)
            )
            .accessibilityIdentifier(badgeIdentifier)

            if accuracy == .mediumAddTime, let onAddTime {
                Button(action: onAddTime) {
                    Text("saju.result.accuracy.addTime", bundle: .main)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DesignTokens.ink)
                        .underline()
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("SajuAccuracyAddTimeCTA")
            }
            Spacer(minLength: 0)
        }
    }

    private var dotColor: Color {
        switch accuracy {
        case .high: return Color(red: 0.2, green: 0.6, blue: 0.3)
        case .medium, .mediumAddTime: return Color(red: 0.9, green: 0.7, blue: 0.2)
        }
    }

    private var label: String {
        switch accuracy {
        case .high:           return String(localized: "saju.result.accuracy.high")
        case .medium:         return String(localized: "saju.result.accuracy.medium")
        case .mediumAddTime:  return String(localized: "saju.result.accuracy.medium")
        }
    }

    private var badgeIdentifier: String {
        switch accuracy {
        case .high: return "SajuAccuracyBadge_high"
        case .medium: return "SajuAccuracyBadge_medium"
        case .mediumAddTime: return "SajuAccuracyBadge_mediumAddTime"
        }
    }
}
