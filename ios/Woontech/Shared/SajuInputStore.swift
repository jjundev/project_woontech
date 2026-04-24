import Foundation
import Combine

/// Observable store for WF2 사주 입력 + 결과 플로우.
/// - Holds `SajuInputModel` / `SajuFlowModel` / optional `SajuResultModel`.
/// - Persists `userProfile` JSON via `UserDefaults`. (NFC-6)
@MainActor
final class SajuInputStore: ObservableObject {

    enum Keys {
        static let userProfile = "userProfile"
        static let isSignedIn = "isSajuSessionSignedIn"
    }

    private let defaults: UserDefaults

    @Published var input: SajuInputModel
    @Published var flow: SajuFlowModel
    @Published private(set) var result: SajuResultModel?
    @Published private(set) var isSignedIn: Bool
    @Published var lastCopiedInviteURL: String?
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""

    init(defaults: UserDefaults = .standard, preload: SajuInputModel? = nil) {
        self.defaults = defaults
        let initialInput: SajuInputModel
        if let preload {
            initialInput = preload
        } else if let data = defaults.data(forKey: Keys.userProfile),
                  let decoded = try? JSONDecoder().decode(SajuInputModel.self, from: data) {
            initialInput = decoded
        } else {
            initialInput = .default
        }
        self.input = initialInput
        self.flow = SajuFlowModel()
        self.isSignedIn = defaults.bool(forKey: Keys.isSignedIn)
    }

    // MARK: - Persistence (NFC-6)

    func persist() {
        guard let data = try? JSONEncoder().encode(input) else { return }
        defaults.set(data, forKey: Keys.userProfile)
    }

    func load() -> SajuInputModel? {
        guard let data = defaults.data(forKey: Keys.userProfile),
              let decoded = try? JSONDecoder().decode(SajuInputModel.self, from: data) else {
            return nil
        }
        input = decoded
        return decoded
    }

    func resetForTests() {
        defaults.removeObject(forKey: Keys.userProfile)
        defaults.removeObject(forKey: Keys.isSignedIn)
        input = .default
        flow = SajuFlowModel()
        result = nil
        isSignedIn = false
    }

    func setSignedInForTesting(_ value: Bool) {
        isSignedIn = value
        defaults.set(value, forKey: Keys.isSignedIn)
    }

    // MARK: - Analysis

    /// 동기 분석 + 결과 반영. FR-8.2.
    func runAnalysis() {
        result = SajuAnalysisEngine.analyze(input: input)
        persist()
    }

    /// 입력 업데이트 후 결과 화면에서 보고 있었다면 재분석. FR-8.7 / AC-19.
    func reanalyzeIfOnResult() {
        if flow.currentStep == .result {
            runAnalysis()
        }
    }

    // MARK: - Navigation intents

    func advance() {
        flow.advance(using: input)
    }

    func back() -> Bool {
        flow.back(using: input)
    }

    // MARK: - Step 8 edit flow

    func startEdit(targetStep: SajuStep) {
        flow.jump(to: targetStep)
    }

    func finishEditReturnToResult() {
        flow.completeEditReturn()
        runAnalysis()
    }

    // MARK: - Invite code (FR-10.2)

    /// 5자리 영숫자 초대 코드. 프로필 유도(결정적): 이름 + 생년월일.
    var inviteCode: String {
        let seed = "\(input.normalizedName)|\(input.birthDate.year)-\(input.birthDate.month)-\(input.birthDate.day)"
        var hash: UInt64 = 2166136261
        for byte in seed.utf8 {
            hash ^= UInt64(byte)
            hash &*= 16777619
        }
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        var code = ""
        for i in 0..<5 {
            let idx = Int((hash >> (i * 5)) & UInt64(alphabet.count - 1)) % alphabet.count
            code.append(alphabet[idx])
        }
        return code
    }

    /// FR-10.8 / AC-25. 초대 URL 포맷.
    var inviteURL: String {
        "https://woontech.app/invite/\(inviteCode)"
    }

    func copyInviteLink() {
        lastCopiedInviteURL = inviteURL
        presentToast("복사되었어요")
    }

    // MARK: - Toast

    func presentToast(_ message: String) {
        toastMessage = message
        showToast = true
    }

    func dismissToast() {
        showToast = false
    }
}
