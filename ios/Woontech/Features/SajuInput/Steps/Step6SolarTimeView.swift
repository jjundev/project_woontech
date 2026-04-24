import SwiftUI

/// Step 6 — 진태양시 보정. FR-6.x / AC-11, AC-12, AC-13.
struct Step6SolarTimeView: View {
    @EnvironmentObject private var store: SajuInputStore
    @State private var showsSheet: Bool = false

    private var longitude: Double {
        switch store.input.birthPlace {
        case .domestic(let id):
            return CityCatalog.shared.city(withID: id)?.longitude ?? 127.0
        case .overseas(let lon):
            return lon.isFinite ? lon : 127.0
        }
    }

    private var correction: SolarTimeCorrectionResult {
        SolarTimeCalculator.correct(
            hour: store.input.birthTime.hour,
            minute: store.input.birthTime.minute,
            longitude: longitude
        )
    }

    var body: some View {
        SajuStepScaffold(
            titleKey: "saju.step6.title",
            hintKey: "saju.step6.hint"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Button(action: { showsSheet = true }) {
                    Text("saju.step6.whats.link", bundle: .main)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DesignTokens.ink)
                        .underline()
                        .frame(minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("SajuWhatsTrueSolarLink")

                SajuToggleRow(
                    titleKey: "saju.step6.toggle.title",
                    subtitleKey: "saju.step6.toggle.subtitle",
                    isOn: Binding(
                        get: { store.input.solarTime.enabled },
                        set: { store.input.solarTime.enabled = $0 }
                    ),
                    identifier: "SajuSolarTimeToggle"
                )

                calculationBox
            }
        }
        .sheet(isPresented: $showsSheet) {
            whatsTrueSolarSheet
                .presentationDetents([.fraction(0.55)])
        }
    }

    private var calculationBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("saju.step6.calc.title", bundle: .main)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)

            calcRow(
                labelKey: "saju.step6.calc.longitude",
                value: String(format: "%.2f°", longitude),
                identifier: "SajuCalcLongitude"
            )
            calcRow(
                labelKey: "saju.step6.calc.offset",
                value: store.input.solarTime.enabled
                    ? "\(correction.offsetMinutes)분"
                    : String(localized: "saju.step6.calc.notApplied"),
                identifier: "SajuCalcOffset"
            )
            calcRow(
                labelKey: "saju.step6.calc.corrected",
                value: store.input.solarTime.enabled
                    ? String(format: "%02d:%02d", correction.correctedHour, correction.correctedMinute)
                    : String(localized: "saju.step6.calc.notApplied"),
                identifier: "SajuCalcCorrected"
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(DesignTokens.gray)
        )
        .accessibilityIdentifier("SajuCalcBox")
    }

    @ViewBuilder
    private func calcRow(labelKey: LocalizedStringKey,
                         value: String,
                         identifier: String) -> some View {
        HStack {
            Text(labelKey, bundle: .main)
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.muted)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
                .accessibilityIdentifier(identifier)
        }
    }

    private var whatsTrueSolarSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("saju.step6.sheet.title", bundle: .main)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(DesignTokens.ink)
                .padding(.top, 16)

            ForEach(0..<3, id: \.self) { i in
                sheetCard(index: i)
            }

            Button(action: { showsSheet = false }) {
                Text("saju.step6.sheet.confirm", bundle: .main)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(DesignTokens.ink)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("SajuSheetConfirm")
        }
        .padding(20)
        .accessibilityIdentifier("SajuWhatsTrueSolarSheet")
    }

    @ViewBuilder
    private func sheetCard(index: Int) -> some View {
        let titles: [LocalizedStringKey] = [
            "saju.step6.sheet.card1.title",
            "saju.step6.sheet.card2.title",
            "saju.step6.sheet.card3.title"
        ]
        let bodies: [LocalizedStringKey] = [
            "saju.step6.sheet.card1.body",
            "saju.step6.sheet.card2.body",
            "saju.step6.sheet.card3.body"
        ]
        VStack(alignment: .leading, spacing: 4) {
            Text(titles[index], bundle: .main)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
            Text(bodies[index], bundle: .main)
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.muted)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(DesignTokens.gray)
        )
    }
}
