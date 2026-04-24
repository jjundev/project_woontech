import SwiftUI

/// 단일 컬럼 휠 피커 — SwiftUI `Picker(.wheel)` 래핑.
struct WheelPickerColumn: View {
    let label: String
    let values: [Int]
    @Binding var selection: Int
    var isEnabled: Bool = true
    var format: (Int) -> String = { String($0) }
    var accessibilityIdentifier: String

    var body: some View {
        Picker(label, selection: $selection) {
            ForEach(values, id: \.self) { value in
                Text(format(value)).tag(value)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.4)
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text(format(selection)))
    }
}
