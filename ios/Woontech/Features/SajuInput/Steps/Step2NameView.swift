import SwiftUI

/// Step 2 — 이름 입력. FR-2.x / AC-3.
struct Step2NameView: View {
    @EnvironmentObject private var store: SajuInputStore
    @FocusState private var focused: Bool

    var body: some View {
        SajuStepScaffold(
            titleKey: "saju.step2.title",
            hintKey: "saju.step2.hint"
        ) {
            VStack(alignment: .leading, spacing: 8) {
                TextField(
                    String(localized: "saju.step2.placeholder"),
                    text: Binding(
                        get: { store.input.name },
                        set: { store.input.name = SajuInputModel.sanitizeName($0) }
                    )
                )
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .focused($focused)
                .font(.system(size: 16))
                .foregroundStyle(DesignTokens.ink)
                .frame(height: 48)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DesignTokens.gray)
                )
                .accessibilityIdentifier("SajuNameField")

                Text("saju.step2.note", bundle: .main)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.muted)
            }
        }
        .onAppear {
            focused = true
        }
    }
}
