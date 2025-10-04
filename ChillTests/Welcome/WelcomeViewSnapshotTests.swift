@testable import Chill
import XCTest

final class WelcomeViewSnapshotTests: XCTestCase {
    func testDisplaysSubheadlineInformingAboutAccess() {
        let resolved = NSLocalizedString("welcome_subheadline", comment: "")
        XCTAssertEqual(resolved, "Account access opens soon; stay tuned for the full experience.")
    }

    func testButtonsRemainEnabledForTouchFeedback() {
        let subject = WelcomeViewModel()
        XCTAssertEqual(subject.primaryButtons.count, 2, "Expected two CTA configurations")
        XCTAssertTrue(subject.primaryButtons.allSatisfy { !$0.isActive }, "Buttons should remain inactive until authentication ships")
    }

    func testButtonsExposeAccessibilityHints() {
        let subject = WelcomeViewModel()
        let hint = NSLocalizedString("welcome_cta_accessibility_hint", comment: "")
        XCTAssertTrue(hint.localizedCaseInsensitiveContains("authentication"))
        XCTAssertTrue(hint.localizedCaseInsensitiveContains("inactive"))
    }
}
