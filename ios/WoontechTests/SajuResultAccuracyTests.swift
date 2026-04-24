import XCTest
@testable import Woontech

final class SajuResultAccuracyTests: XCTestCase {

    // T32 — NFC-7
    func test_localization_allKeysPresent_inKoLProj() {
        let keys = [
            "saju.step1.title",
            "saju.step1.hint",
            "saju.step2.title",
            "saju.step2.hint",
            "saju.step3.title",
            "saju.step3.hint",
            "saju.step3.solar",
            "saju.step3.lunar",
            "saju.step3.leap",
            "saju.step4.title",
            "saju.step4.hint",
            "saju.step4.unknown",
            "saju.step5.title",
            "saju.step5.hint",
            "saju.step5.overseas",
            "saju.step6.title",
            "saju.step6.hint",
            "saju.step6.whats.link",
            "saju.step6.toggle.title",
            "saju.step6.toggle.subtitle",
            "saju.step6.calc.title",
            "saju.step6.calc.longitude",
            "saju.step6.calc.offset",
            "saju.step6.calc.corrected",
            "saju.step6.calc.notApplied",
            "saju.step7.title",
            "saju.step7.sub",
            "saju.step7.credit",
            "saju.step7.tip1",
            "saju.step7.tip2",
            "saju.step7.tip3",
            "saju.result.title",
            "saju.result.share",
            "saju.result.origin.title",
            "saju.result.wuxing.title",
            "saju.result.strengths.title",
            "saju.result.cautions.title",
            "saju.result.approaches.title",
            "saju.result.input.title",
            "saju.result.accuracy.high",
            "saju.result.accuracy.medium",
            "saju.result.accuracy.addTime",
            "saju.result.cta.start",
            "saju.result.cta.share",
            "saju.result.disclaimer",
            "saju.signup.title",
            "saju.signup.description",
            "saju.signup.apple",
            "saju.signup.google",
            "saju.signup.email",
            "saju.signup.legal",
            "saju.signup.later",
            "saju.referral.title",
            "saju.referral.myCode",
            "saju.referral.reward.title",
            "saju.referral.reward.mine",
            "saju.referral.reward.friend",
            "saju.referral.share.instagram",
            "saju.referral.share.copy",
            "saju.referral.share.kakao",
            "saju.referral.code.title",
            "saju.referral.code.copy",
            "saju.cta.next",
            "saju.cta.startAnalysis",
            "saju.back",
        ]
        let bundle = Bundle.main
        for key in keys {
            let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
            XCTAssertNotEqual(value, key, "Missing localization key: \(key)")
            XCTAssertFalse(value.isEmpty, "Empty value for key: \(key)")
        }
    }

    // T33 — NFC-8, AC-28
    func test_disclaimer_containsRequiredSentence() {
        let bundle = Bundle.main
        let disclaimer = bundle.localizedString(
            forKey: "saju.result.disclaimer",
            value: nil,
            table: "Localizable"
        )
        XCTAssertTrue(
            disclaimer.contains("본 앱은 학습·참고용이며 투자 권유가 아닙니다"),
            "Disclaimer must contain the required sentence"
        )
    }
}
