import Foundation

/// 사주 분석 엔진. 1차 릴리스는 **결정적 스텁** — 생년월일·시간·출생지 해시로 유형을
/// 고정 반환한다(이름은 라벨에만 영향). 실제 Swiss Ephemeris 기반 계산은 동일 인터페이스로 교체한다.
enum SajuAnalysisEngine {
    static let minimumDisplayInterval: TimeInterval = 1.8

    /// 입력값으로부터 결정적인 결과를 생성한다.
    static func analyze(input: SajuInputModel) -> SajuResultModel {
        let typeHash = stableHash(for: input)
        let type = Self.types[typeHash % Self.types.count]

        // 4주 — 스텁 데이터 (한자).
        let hour = SajuPillar(
            stem: "丁", branch: "巳",
            stemElement: "화", branchElement: "화", isDayPillar: false
        )
        let day = SajuPillar(
            stem: "庚", branch: "申",
            stemElement: "금", branchElement: "금", isDayPillar: true
        )
        let month = SajuPillar(
            stem: "己", branch: "卯",
            stemElement: "토", branchElement: "목", isDayPillar: false
        )
        let year = SajuPillar(
            stem: "庚", branch: "午",
            stemElement: "금", branchElement: "화", isDayPillar: false
        )

        let wuxing: [WuxingBar] = [
            .init(element: .wood, value: 0.2),
            .init(element: .fire, value: 0.6),
            .init(element: .earth, value: 0.3),
            .init(element: .metal, value: 0.7),
            .init(element: .water, value: 0.0)
        ]

        let inputSummary = Self.makeInputSummary(input: input)

        return SajuResultModel(
            typeName: type.name,
            dayPillarSummary: type.dayPillar,
            oneLiner: type.oneLiner,
            hourPillar: input.birthTime.hourKnown ? hour : .unknown,
            dayPillar: day,
            monthPillar: month,
            yearPillar: year,
            hourUnknown: !input.birthTime.hourKnown,
            wuxing: wuxing,
            wuxingWarning: "水 부재 · 火·金 과다 — 충동 판단 제어 필요",
            strengths: [
                "분석력과 인내심이 뛰어나요",
                "큰 흐름을 파악하는 눈이 있어요",
                "리스크 관리 감각이 있어요"
            ],
            cautions: [
                "충동 매수에 주의하세요",
                "수익 실현 타이밍을 놓치기 쉬워요",
                "과도한 분석은 결정을 미루게 해요"
            ],
            approaches: [
                "분산 투자로 리스크를 나눠보세요",
                "중기 흐름에 집중해 보세요",
                "매매 전 체크리스트 루틴을 만들어보세요"
            ],
            dayMasterNature: type.dayMasterNature,
            investmentTags: type.investmentTags,
            inputSummary: inputSummary,
            accuracy: input.accuracy
        )
    }

    // MARK: - Helpers

    private struct StubType {
        let name: String
        let dayPillar: String
        let oneLiner: String
        let dayMasterNature: String
        let investmentTags: String
    }

    private static let types: [StubType] = [
        .init(name: "단단한 수집가형", dayPillar: "경금(庚金) 일주 · 정재 중심",
              oneLiner: "분석과 인내의 장기 플레이어",
              dayMasterNature: "강철", investmentTags: "원칙형 · 관리형"),
        .init(name: "흐름 파도형", dayPillar: "병화(丙火) 일주 · 식신 중심",
              oneLiner: "흐름을 읽고 타이밍을 잡는 유형",
              dayMasterNature: "태양", investmentTags: "타이밍형 · 감각형"),
        .init(name: "묵묵한 축적형", dayPillar: "기토(己土) 일주 · 정인 중심",
              oneLiner: "꾸준함으로 자산을 쌓아가는 유형",
              dayMasterNature: "논밭", investmentTags: "안정형 · 축적형"),
        .init(name: "감각적 탐험형", dayPillar: "을목(乙木) 일주 · 편재 중심",
              oneLiner: "호기심과 유연함으로 기회를 포착",
              dayMasterNature: "풀꽃", investmentTags: "탐험형 · 유연형"),
        .init(name: "깊이 관찰형", dayPillar: "임수(壬水) 일주 · 비견 중심",
              oneLiner: "신중한 판단과 장기 관찰의 유형",
              dayMasterNature: "바다", investmentTags: "관찰형 · 신중형")
    ]

    /// Name-agnostic stable hash. 이름은 라벨에만 영향을 주고 유형은 바뀌지 않도록 한다.
    static func stableHash(for input: SajuInputModel) -> Int {
        var seed: UInt64 = 1469598103934665603 // FNV offset basis
        func mix(_ v: UInt64) {
            seed ^= v
            seed &*= 1099511628211 // FNV prime
        }
        mix(UInt64(bitPattern: Int64(input.birthDate.year)))
        mix(UInt64(bitPattern: Int64(input.birthDate.month)))
        mix(UInt64(bitPattern: Int64(input.birthDate.day)))
        mix(UInt64(input.birthDate.kind.isSolar ? 1 : 2))
        mix(UInt64(input.birthDate.kind.isLeap ? 1 : 0))
        mix(UInt64(bitPattern: Int64(input.birthTime.hour)))
        mix(UInt64(bitPattern: Int64(input.birthTime.minute)))
        mix(UInt64(input.birthTime.hourKnown ? 1 : 0))
        switch input.birthPlace {
        case .domestic(let id):
            for byte in id.utf8 { mix(UInt64(byte)) }
        case .overseas(let lon):
            mix(UInt64(bitPattern: Int64(lon * 100)))
        }
        mix(UInt64(input.solarTime.enabled ? 1 : 0))
        // Clamp to non-negative Int.
        return Int(seed & 0x7fff_ffff_ffff_ffff)
    }

    static func makeInputSummary(input: SajuInputModel) -> String {
        let d = input.birthDate
        let kindLabel: String
        switch d.kind {
        case .solar: kindLabel = "양력"
        case .lunar(let leap): kindLabel = leap ? "음력(윤달)" : "음력"
        }
        let dateStr = String(format: "%04d.%02d.%02d", d.year, d.month, d.day)
        let timeStr: String
        if input.birthTime.hourKnown {
            timeStr = String(format: "%02d:%02d", input.birthTime.hour, input.birthTime.minute)
        } else {
            timeStr = "시간 미입력"
        }
        let place: String
        switch input.birthPlace {
        case .domestic(let id):
            place = CityCatalog.shared.city(withID: id)?.name ?? "출생지 미지정"
        case .overseas(let lon):
            place = String(format: "국외 (경도 %.2f°)", lon)
        }
        let gender: String
        switch input.gender {
        case .some(.male): gender = "남"
        case .some(.female): gender = "여"
        case .none: gender = "성별 미선택"
        }
        return "\(kindLabel) \(dateStr) \(timeStr) · \(place) · \(gender)"
    }
}
