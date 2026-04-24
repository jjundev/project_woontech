import SwiftUI

/// Step 4 — 태어난 시간. FR-4.x / AC-6, AC-7.
struct Step4BirthTimeView: View {
    @EnvironmentObject private var store: SajuInputStore

    /// 15분 간격 기본 옵션 + 임의 분 5분 간격. FR-4.2.
    private static let minuteValues: [Int] = Array(0...59)

    var body: some View {
        SajuStepScaffold(
            titleKey: "saju.step4.title",
            hintKey: "saju.step4.hint"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 0) {
                    WheelPickerColumn(
                        label: String(localized: "saju.step4.hour"),
                        values: Array(0...23),
                        selection: Binding(
                            get: { store.input.birthTime.hour },
                            set: { store.input.birthTime.hour = $0 }
                        ),
                        isEnabled: store.input.birthTime.hourKnown,
                        format: { String(format: "%02d", $0) },
                        accessibilityIdentifier: "SajuHourPicker"
                    )
                    WheelPickerColumn(
                        label: String(localized: "saju.step4.minute"),
                        values: Step4BirthTimeView.minuteValues,
                        selection: Binding(
                            get: { store.input.birthTime.minute },
                            set: { store.input.birthTime.minute = $0 }
                        ),
                        isEnabled: store.input.birthTime.hourKnown,
                        format: { String(format: "%02d", $0) },
                        accessibilityIdentifier: "SajuMinutePicker"
                    )
                }
                .frame(height: 160)

                SajuCheckbox(
                    titleKey: "saju.step4.unknown",
                    isChecked: Binding(
                        get: { !store.input.birthTime.hourKnown },
                        set: { checked in
                            store.input.birthTime.hourKnown = !checked
                        }
                    ),
                    identifier: "SajuHourUnknownCheckbox"
                )
            }
        }
    }
}
