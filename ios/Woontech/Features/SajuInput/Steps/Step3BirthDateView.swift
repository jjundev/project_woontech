import SwiftUI

/// Step 3 — 생년월일. FR-3.x / AC-4, AC-5.
struct Step3BirthDateView: View {
    @EnvironmentObject private var store: SajuInputStore

    private enum CalendarChoice: Hashable { case solar, lunar }

    var body: some View {
        SajuStepScaffold(
            titleKey: "saju.step3.title",
            hintKey: "saju.step3.hint"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                // 양력 / 음력 세그먼트
                SajuSegmented(
                    options: [
                        SajuSegmentedOption(
                            value: CalendarChoice.solar,
                            titleKey: "saju.step3.solar",
                            identifier: "SajuCalendarSolar"
                        ),
                        SajuSegmentedOption(
                            value: CalendarChoice.lunar,
                            titleKey: "saju.step3.lunar",
                            identifier: "SajuCalendarLunar"
                        )
                    ],
                    selection: Binding(
                        get: {
                            store.input.birthDate.kind.isSolar
                                ? CalendarChoice.solar
                                : CalendarChoice.lunar
                        },
                        set: { choice in
                            switch choice {
                            case .solar:
                                store.input.birthDate.kind = .solar
                            case .lunar:
                                store.input.birthDate.kind = .lunar(leap: false)
                            }
                        }
                    )
                )

                if store.input.birthDate.kind.isLunar {
                    SajuCheckbox(
                        titleKey: "saju.step3.leap",
                        isChecked: Binding(
                            get: { store.input.birthDate.kind.isLeap },
                            set: { newVal in
                                store.input.birthDate.kind = .lunar(leap: newVal)
                            }
                        ),
                        isEnabled: LunarCalendar.hasLeapMonth(
                            year: store.input.birthDate.year,
                            month: store.input.birthDate.month
                        ),
                        identifier: "SajuLeapCheckbox"
                    )
                }

                // 3-column 휠
                HStack(spacing: 0) {
                    WheelPickerColumn(
                        label: String(localized: "saju.step3.year"),
                        values: Array(BirthDate.yearRange()),
                        selection: Binding(
                            get: { store.input.birthDate.year },
                            set: { newVal in
                                store.input.birthDate.year = newVal
                                clampDayIfNeeded()
                            }
                        ),
                        format: { String($0) },
                        accessibilityIdentifier: "SajuYearPicker"
                    )
                    WheelPickerColumn(
                        label: String(localized: "saju.step3.month"),
                        values: Array(1...12),
                        selection: Binding(
                            get: { store.input.birthDate.month },
                            set: { newVal in
                                store.input.birthDate.month = newVal
                                clampDayIfNeeded()
                            }
                        ),
                        format: { String(format: "%02d", $0) },
                        accessibilityIdentifier: "SajuMonthPicker"
                    )
                    WheelPickerColumn(
                        label: String(localized: "saju.step3.day"),
                        values: Array(1...validDays),
                        selection: Binding(
                            get: { store.input.birthDate.day },
                            set: { store.input.birthDate.day = $0 }
                        ),
                        format: { String(format: "%02d", $0) },
                        accessibilityIdentifier: "SajuDayPicker"
                    )
                }
                .frame(height: 160)
            }
        }
    }

    private var validDays: Int {
        BirthDate.daysInMonth(
            year: store.input.birthDate.year,
            month: store.input.birthDate.month
        )
    }

    private func clampDayIfNeeded() {
        let maxDay = validDays
        if store.input.birthDate.day > maxDay {
            store.input.birthDate.day = maxDay
        }
    }
}

/// 음력 윤달 판별 헬퍼 — iOS `Calendar(.chinese)`를 사용.
enum LunarCalendar {
    /// 해당 (양력 기준) 연도의 (음력) 월에 윤달이 존재하는지 대략 판별.
    /// 1차 스텁: `Calendar(.chinese)` 기반 범위에서 윤달(isLeapMonth)을 탐색.
    static func hasLeapMonth(year: Int, month: Int) -> Bool {
        var cal = Calendar(identifier: .chinese)
        cal.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let gregorian = Calendar(identifier: .gregorian)
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        guard let start = gregorian.date(from: comps) else { return false }
        // Walk through the year and find if any day is a leap month matching `month`.
        let oneYear: TimeInterval = 60 * 60 * 24 * 370
        let end = start.addingTimeInterval(oneYear)
        var cursor = start
        while cursor <= end {
            let chineseComps = cal.dateComponents([.month, .isLeapMonth], from: cursor)
            if chineseComps.isLeapMonth == true,
               chineseComps.month == month {
                return true
            }
            cursor = cursor.addingTimeInterval(60 * 60 * 24 * 15)
        }
        return false
    }
}
