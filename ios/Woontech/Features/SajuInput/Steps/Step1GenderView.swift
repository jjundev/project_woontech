import SwiftUI

/// Step 1 — 성별 선택. FR-1.x / AC-1, AC-2.
struct Step1GenderView: View {
    @EnvironmentObject private var store: SajuInputStore

    var body: some View {
        SajuStepScaffold(
            titleKey: "saju.step1.title",
            hintKey: "saju.step1.hint"
        ) {
            HStack(spacing: 12) {
                genderBox(.male,
                          titleKey: "saju.step1.male",
                          identifier: "SajuGenderMale")
                genderBox(.female,
                          titleKey: "saju.step1.female",
                          identifier: "SajuGenderFemale")
            }
        }
    }

    @ViewBuilder
    private func genderBox(_ gender: Gender,
                           titleKey: LocalizedStringKey,
                           identifier: String) -> some View {
        let isSelected = store.input.gender == gender
        Button(action: { store.input.gender = gender }) {
            Text(titleKey, bundle: .main)
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundStyle(DesignTokens.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 96)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? DesignTokens.gray : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? DesignTokens.ink : DesignTokens.line3,
                                lineWidth: isSelected ? 2 : 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}
