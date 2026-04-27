import SwiftUI
import UIKit

/// Step 10 — 친구 초대 화면. FR-10.x / AC-23~25.
struct Step10ReferralView: View {
    @EnvironmentObject private var store: SajuInputStore
    var onBack: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerRow

                    // 혜택 카드
                    rewardCard

                    if let result = store.result {
                        ShareCardView(
                            result: result,
                            displayNameLabel: store.input.displayNameLabel,
                            dateLabel: ShareCardView.todayLabel()
                        )
                        .frame(height: 360)
                        .accessibilityIdentifier("SajuReferralPreview")
                    }

                    // 공유 CTA 3개
                    VStack(spacing: 10) {
                        shareButton(titleKey: "saju.referral.share.instagram",
                                    identifier: "SajuReferralInstagram",
                                    primary: true)
                        shareButton(titleKey: "saju.referral.share.copy",
                                    identifier: "SajuReferralCopyLink",
                                    primary: false,
                                    action: { store.copyInviteLink() })
                        shareButton(titleKey: "saju.referral.share.kakao",
                                    identifier: "SajuReferralKakao",
                                    primary: false)
                    }

                    inviteCodeCard

                    if store.showToast {
                        Text(store.toastMessage)
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(DesignTokens.ink)
                            )
                            .accessibilityIdentifier("SajuReferralToast")
                    }
                }
                .padding(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.bg)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("SajuReferralRoot")
    }

    private var headerRow: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("SajuReferralBack")

            Text("saju.referral.title", bundle: .main)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
                .accessibilityAddTraits(.isHeader)

            Spacer()
            Text(String(format: String(localized: "saju.referral.myCode"), store.inviteCode))
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.muted)
                .accessibilityIdentifier("SajuReferralHeaderCode")
        }
    }

    private var rewardCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("saju.referral.reward.title", bundle: .main)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
            HStack(spacing: 12) {
                rewardChip(titleKey: "saju.referral.reward.mine")
                rewardChip(titleKey: "saju.referral.reward.friend")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.gray)
        )
        .accessibilityIdentifier("SajuReferralRewardCard")
    }

    @ViewBuilder
    private func rewardChip(titleKey: LocalizedStringKey) -> some View {
        Text(titleKey, bundle: .main)
            .font(.system(size: 12))
            .foregroundStyle(DesignTokens.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.white)
            )
    }

    @ViewBuilder
    private func shareButton(titleKey: LocalizedStringKey,
                             identifier: String,
                             primary: Bool,
                             action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            Text(titleKey, bundle: .main)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(primary ? .white : DesignTokens.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(primary ? DesignTokens.ink : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(primary ? DesignTokens.ink : DesignTokens.ink, lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }

    private var inviteCodeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("saju.referral.code.title", bundle: .main)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
            HStack(spacing: 8) {
                Text(store.inviteCode)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(DesignTokens.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6).fill(DesignTokens.gray)
                    )
                    .accessibilityIdentifier("SajuReferralCode")
                Spacer()
                Button(action: { store.copyInviteLink() }) {
                    Text("saju.referral.code.copy", bundle: .main)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignTokens.ink)
                        .padding(.horizontal, 10)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("SajuReferralCopyCodeButton")
            }
            Text("saju.referral.summary", bundle: .main)
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
        .accessibilityIdentifier("SajuReferralCodeCard")
    }
}
