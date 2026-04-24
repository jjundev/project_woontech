import SwiftUI
import UIKit

/// Step 8 — 나의 투자 성향 결과 단일 화면. FR-8.x.
struct Step8ResultView: View {
    @EnvironmentObject private var store: SajuInputStore
    var onStart: () -> Void

    @State private var shareItem: ShareItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerRow

                if let result = store.result {
                    HeroTypeCardView(
                        label: store.input.displayNameLabel,
                        typeName: result.typeName,
                        dayPillarSummary: result.dayPillarSummary,
                        oneLiner: result.oneLiner
                    )

                    AccuracyBadgeView(
                        accuracy: result.accuracy,
                        onAddTime: result.accuracy == .mediumAddTime
                            ? { store.startEdit(targetStep: .birthTime) }
                            : nil
                    )

                    SajuMiniChartView(
                        hourPillar: result.hourPillar,
                        dayPillar: result.dayPillar,
                        monthPillar: result.monthPillar,
                        yearPillar: result.yearPillar,
                        hourUnknown: result.hourUnknown,
                        metaLabel: result.inputSummary
                    )

                    WuxingBalanceBarView(
                        bars: result.wuxing,
                        warning: result.wuxingWarning
                    )

                    BulletListView(
                        style: .strength,
                        titleKey: "saju.result.strengths.title",
                        items: result.strengths,
                        identifier: "SajuStrengths"
                    )

                    BulletListView(
                        style: .caution,
                        titleKey: "saju.result.cautions.title",
                        items: result.cautions,
                        identifier: "SajuCautions"
                    )

                    BulletListView(
                        style: .approach,
                        titleKey: "saju.result.approaches.title",
                        items: result.approaches,
                        identifier: "SajuApproaches"
                    )

                    inputSummaryCard(result)
                }

                ctaRow

                Text("saju.result.disclaimer", bundle: .main)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.muted)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("SajuDisclaimer")
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.bg)
        .accessibilityIdentifier("SajuResultRoot")
        .onAppear {
            // Ensure result exists + persist (NFC-6).
            if store.result == nil {
                store.runAnalysis()
            } else {
                store.persist()
            }
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(activityItems: [item.image])
        }
    }

    private var headerRow: some View {
        HStack {
            Text("saju.result.title", bundle: .main)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("SajuResultTitle")
            Spacer()
            Button(action: handleShare) {
                Text("saju.result.share", bundle: .main)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DesignTokens.ink)
                    .underline()
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("SajuResultShareLink")
        }
    }

    @ViewBuilder
    private func inputSummaryCard(_ result: SajuResultModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("saju.result.input.title", bundle: .main)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
            Text(result.inputSummary)
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.muted)

            HStack(spacing: 8) {
                editButton(titleKey: "saju.result.input.edit.birthDate",
                           target: .birthDate,
                           identifier: "SajuEditBirthDate")
                editButton(titleKey: "saju.result.input.edit.name",
                           target: .name,
                           identifier: "SajuEditName")
                editButton(titleKey: "saju.result.input.edit.birthTime",
                           target: .birthTime,
                           identifier: "SajuEditBirthTime")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
        .accessibilityIdentifier("SajuInputSummary")
    }

    @ViewBuilder
    private func editButton(titleKey: LocalizedStringKey,
                            target: SajuStep,
                            identifier: String) -> some View {
        Button(action: { store.startEdit(targetStep: target) }) {
            Text(titleKey, bundle: .main)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
                .padding(.horizontal, 10)
                .frame(minHeight: 44)
                .background(
                    Capsule().fill(DesignTokens.gray)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }

    private var ctaRow: some View {
        VStack(spacing: 10) {
            PrimaryButton(titleKey: "saju.result.cta.start", isEnabled: true, action: onStart)
                .accessibilityIdentifier("SajuResultStartCTA")
            Button(action: handleShare) {
                Text("saju.result.cta.share", bundle: .main)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(DesignTokens.ink, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("SajuResultShareCTA")
        }
    }

    private func handleShare() {
        guard let result = store.result else { return }
        let image = ShareCardRenderer.renderImage {
            ShareCardView(
                result: result,
                displayNameLabel: store.input.displayNameLabel,
                dateLabel: ShareCardView.todayLabel()
            )
        }
        if let image {
            shareItem = ShareItem(image: image)
        }
    }
}

struct ShareItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
