import SwiftUI

struct DisclaimerCheckboxView: View {
    @Binding var checked: Bool

    var body: some View {
        Button {
            checked.toggle()
        } label: {
            HStack(alignment: .top, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(DesignTokens.ink, lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(checked ? DesignTokens.ink : Color.clear)
                        )
                        .frame(width: 16, height: 16)

                    if checked {
                        Path { path in
                            path.move(to: CGPoint(x: 3, y: 8))
                            path.addLine(to: CGPoint(x: 6.5, y: 11))
                            path.addLine(to: CGPoint(x: 13, y: 4))
                        }
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                        .frame(width: 16, height: 16)
                    }
                }
                .padding(.top, 1)

                Text("onboarding.disclaimer.checkbox", bundle: .main)
                    .font(.system(size: 10))
                    .foregroundStyle(DesignTokens.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("onboarding.disclaimer.checkbox", bundle: .main))
        .accessibilityAddTraits(checked ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("OnboardingDisclaimerCheckbox")
    }
}
