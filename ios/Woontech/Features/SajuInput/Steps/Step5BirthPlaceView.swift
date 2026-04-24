import SwiftUI

/// Step 5 — 출생지. FR-5.x / AC-8, AC-9.
struct Step5BirthPlaceView: View {
    @EnvironmentObject private var store: SajuInputStore
    @State private var query: String = ""
    @State private var longitudeText: String = ""
    @FocusState private var searchFocused: Bool

    private var catalog: CityCatalog { CityCatalog.shared }

    var body: some View {
        SajuStepScaffold(
            titleKey: "saju.step5.title",
            hintKey: "saju.step5.hint"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                if case .domestic = store.input.birthPlace {
                    searchBox
                    cityList
                } else {
                    overseasField
                }

                SajuCheckbox(
                    titleKey: "saju.step5.overseas",
                    isChecked: Binding(
                        get: { store.input.birthPlace.isOverseas },
                        set: { checked in
                            if checked {
                                store.input.birthPlace = .overseas(longitude: 0)
                                longitudeText = ""
                            } else {
                                store.input.birthPlace = .domestic(cityID: CityCatalog.defaultCityID)
                            }
                        }
                    ),
                    identifier: "SajuOverseasCheckbox"
                )
            }
        }
        .onAppear {
            if case .overseas(let lon) = store.input.birthPlace {
                longitudeText = String(format: "%.2f", lon)
            }
        }
    }

    private var searchBox: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(DesignTokens.muted)
            TextField(
                String(localized: "saju.step5.search.placeholder"),
                text: $query
            )
            .focused($searchFocused)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .font(.system(size: 14))
            .accessibilityIdentifier("SajuCitySearchField")
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(DesignTokens.gray)
        )
    }

    private var cityList: some View {
        let results = query.isEmpty
            ? catalog.primaryCities
            : catalog.search(query)
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(results) { city in
                cityRow(city)
                Divider().padding(.leading, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(DesignTokens.line3, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func cityRow(_ city: SajuCity) -> some View {
        let selected = {
            if case .domestic(let id) = store.input.birthPlace { return id == city.id }
            return false
        }()
        Button(action: {
            store.input.birthPlace = .domestic(cityID: city.id)
        }) {
            HStack {
                Text(city.name)
                    .font(.system(size: 14, weight: selected ? .semibold : .regular))
                    .foregroundStyle(DesignTokens.ink)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DesignTokens.ink)
                }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("SajuCity_\(city.id)")
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : [.isButton])
    }

    private var overseasField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("saju.step5.longitude.label", bundle: .main)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignTokens.muted)

            TextField(
                String(localized: "saju.step5.longitude.placeholder"),
                text: Binding(
                    get: { longitudeText },
                    set: { newVal in
                        longitudeText = newVal
                        if let parsed = Double(newVal) {
                            store.input.birthPlace = .overseas(longitude: parsed)
                        } else {
                            // Invalid input — treat as out-of-range.
                            store.input.birthPlace = .overseas(longitude: .nan)
                        }
                    }
                )
            )
            .keyboardType(.numbersAndPunctuation)
            .font(.system(size: 16))
            .frame(height: 48)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(DesignTokens.gray)
            )
            .accessibilityIdentifier("SajuLongitudeField")

            Text("saju.step5.longitude.hint", bundle: .main)
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.muted)
        }
    }
}
