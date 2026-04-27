import SwiftUI
import UIKit

/// Step 8 — 나의 투자 성향 결과 단일 화면. FR-8.x.
struct Step8ResultView: View {
    @EnvironmentObject private var store: SajuInputStore
    var onStart: () -> Void

    @State private var shareItem: ShareItem?
    @State private var sectionVisible: [Bool] = Array(repeating: false, count: 7)
    @State private var isAtBottom: Bool = false

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerRow
                    .opacity(sectionVisible[0] ? 1 : 0)
                    .offset(y: sectionVisible[0] ? 0 : 20)

                if let result = store.result {
                    HeroTypeCardView(
                        label: store.input.displayNameLabel,
                        typeName: result.typeName,
                        dayPillarSummary: result.dayPillarSummary,
                        oneLiner: result.oneLiner
                    )
                    .opacity(sectionVisible[1] ? 1 : 0)
                    .offset(y: sectionVisible[1] ? 0 : 20)

                    SajuMiniChartView(
                        hourPillar: result.hourPillar,
                        dayPillar: result.dayPillar,
                        monthPillar: result.monthPillar,
                        yearPillar: result.yearPillar,
                        hourUnknown: result.hourUnknown,
                        dayMasterNature: result.dayMasterNature,
                        wuxing: result.wuxing,
                        strongElements: result.strongElements,
                        supplementElements: result.supplementElements,
                        investmentTags: result.investmentTags
                    )
                    .opacity(sectionVisible[2] ? 1 : 0)
                    .offset(y: sectionVisible[2] ? 0 : 20)

                    BulletListView(
                        style: .strength,
                        titleKey: "saju.result.strengths.title",
                        items: result.strengths,
                        identifier: "SajuStrengths"
                    )
                    .opacity(sectionVisible[3] ? 1 : 0)
                    .offset(y: sectionVisible[3] ? 0 : 20)

                    BulletListView(
                        style: .caution,
                        titleKey: "saju.result.cautions.title",
                        items: result.cautions,
                        identifier: "SajuCautions"
                    )
                    .opacity(sectionVisible[4] ? 1 : 0)
                    .offset(y: sectionVisible[4] ? 0 : 20)

                    BulletListView(
                        style: .approach,
                        titleKey: "saju.result.approaches.title",
                        items: result.approaches,
                        identifier: "SajuApproaches"
                    )
                    .opacity(sectionVisible[5] ? 1 : 0)
                    .offset(y: sectionVisible[5] ? 0 : 20)

                }

                ctaRow
                    .opacity(sectionVisible[6] ? 1 : 0)
                    .offset(y: sectionVisible[6] ? 0 : 20)

                Text("saju.result.disclaimer", bundle: .main)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityIdentifier("SajuDisclaimer")
                    .opacity(sectionVisible[6] ? 1 : 0)
                    .offset(y: sectionVisible[6] ? 0 : 20)

                Color.clear
                    .frame(height: 1)
                    .id("sajuResultBottom")
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: BottomVisibilityKey.self,
                                value: geo.frame(in: .global).minY
                            )
                        }
                    )
            }
            .padding(20)
        }
        .onPreferenceChange(BottomVisibilityKey.self) { minY in
            let screenHeight = UIScreen.main.bounds.height
            withAnimation(.easeInOut(duration: 0.2)) {
                isAtBottom = minY <= screenHeight
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.bg)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("SajuResultRoot")
        .onAppear {
            // Ensure result exists + persist (NFC-6).
            if store.result == nil {
                store.runAnalysis()
            } else {
                store.persist()
                animateIn()
            }
        }
        .onChange(of: store.result) { result in
            if result != nil { animateIn() }
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(activityItems: [item.image])
        }
        .overlay(alignment: .bottomTrailing) {
            if !isAtBottom {
                Button {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo("sajuResultBottom", anchor: .bottom)
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DesignTokens.bg)
                        .frame(width: 52, height: 52)
                        .background(DesignTokens.ink)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24)
                .padding(.trailing, 20)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .accessibilityIdentifier("SajuResultScrollFAB")
                .accessibilityLabel("화면 아래로 스크롤")
            }
        }
        } // ScrollViewReader
    }

    private func animateIn() {
        guard !sectionVisible[0] else { return }
        let delays: [Double] = [0, 0.22, 0.44, 0.66, 0.88, 1.10, 1.32]
        for (i, delay) in delays.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                    sectionVisible[i] = true
                }
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 8) {
            Text("saju.result.title", bundle: .main)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("SajuResultTitle")

            if let result = store.result {
                AccuracyBadgeView(
                    accuracy: result.accuracy,
                    onAddTime: result.accuracy == .mediumAddTime
                        ? { store.startEdit(targetStep: .birthTime) }
                        : nil
                )
            }

            Button(action: store.restartInput) {
                Text("saju.result.reinput", bundle: .main)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DesignTokens.ink)
                    .underline()
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("SajuResultReinputButton")
        }
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

private struct BottomVisibilityKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
