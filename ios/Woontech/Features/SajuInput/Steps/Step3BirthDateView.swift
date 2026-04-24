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
    /// 해당 (양력 기준) 연도의 (음력) 월에 윤달이 존재하는지 판별.
    ///
    /// 개선 포인트 (기존 스텁 대비):
    /// - 탐색 시작점: `(year, month, 1)` 대신 `(year, 1, 1)` — 중국력 연도가 그레고리력 연도와
    ///   ±1~2개월 어긋나므로, 연도 전체를 커버해야 윤달 누락이 없음.
    /// - 탐색 간격: 15일 → 7일 — 윤달(29–30일)을 반드시 4회 이상 히트.
    /// - 탐색 범위: 370일 → 395일 — 늦은 윤달(예: 閏十二月) 버퍼 확보.
    /// - 타임존: UTC+0 → Asia/Seoul — 한국 사용자 기준 날짜 경계 정합.
    /// - 날짜 연산: `addingTimeInterval` → `date(byAdding:)` — DST 안전.
    static func hasLeapMonth(year: Int, month: Int) -> Bool {
        var chineseCal = Calendar(identifier: .chinese)
        chineseCal.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        let gregorian = Calendar(identifier: .gregorian)

        var startComps = DateComponents()
        startComps.year = year
        startComps.month = 1
        startComps.day = 1
        guard let yearStart = gregorian.date(from: startComps) else { return false }

        for offset in stride(from: 0, through: 395, by: 7) {
            guard let date = gregorian.date(byAdding: .day, value: offset, to: yearStart) else { continue }
            let comps = chineseCal.dateComponents([.month, .isLeapMonth], from: date)
            if comps.isLeapMonth == true, comps.month == month {
                return true
            }
        }
        return false
    }
}
