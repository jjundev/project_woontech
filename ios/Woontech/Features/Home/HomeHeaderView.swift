import SwiftUI

// MARK: - Badge helper (internal for unit test access via @testable import)
func badgeLabel(for count: Int) -> String? {
    guard count > 0 else { return nil }
    return count >= 100 ? "99+" : "\(count)"
}

struct HomeHeaderView: View {
    let userProfile: any UserProfileProviding
    let notificationCenter: any NotificationCenterProviding
    var onBellTap: () -> Void = {}
    var onAvatarTap: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            Text("운테크")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier("HomeWordmark")

            Spacer(minLength: 8)

            // Bell button with unread badge overlay
            Button(action: onBellTap) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 22))
                        .foregroundStyle(DesignTokens.ink)
                        .frame(width: 44, height: 44)

                    if let label = badgeLabel(for: notificationCenter.unreadCount) {
                        Text(label)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .offset(x: 6, y: -4)
                            .accessibilityIdentifier("HomeBellBadge")
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("알림 \(notificationCenter.unreadCount)개")
            .accessibilityIdentifier("HomeBellButton")

            // Avatar circle button
            Button(action: onAvatarTap) {
                Circle()
                    .fill(DesignTokens.avatarBg)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Text(userProfile.avatarInitial)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(DesignTokens.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("프로필 \(userProfile.displayName)")
            .accessibilityIdentifier("HomeAvatarButton")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DesignTokens.bg)
    }
}
