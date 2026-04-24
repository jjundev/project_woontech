import SwiftUI

/// 간단한 2+버튼 세그먼트(양력/음력). FR-3.2.
struct SajuSegmentedOption<Value: Hashable>: Identifiable {
    let id = UUID()
    let value: Value
    let titleKey: LocalizedStringKey
    let identifier: String
}

struct SajuSegmented<Value: Hashable>: View {
    let options: [SajuSegmentedOption<Value>]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options) { option in
                Button {
                    selection = option.value
                } label: {
                    Text(option.titleKey, bundle: .main)
                        .font(.system(size: 13, weight: option.value == selection ? .semibold : .regular))
                        .foregroundStyle(option.value == selection ? Color.white : DesignTokens.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(option.value == selection ? DesignTokens.ink : DesignTokens.gray)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(option.identifier)
                .accessibilityAddTraits(option.value == selection ? [.isButton, .isSelected] : [.isButton])
            }
        }
    }
}
