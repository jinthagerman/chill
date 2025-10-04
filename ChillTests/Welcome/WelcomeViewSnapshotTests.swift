@testable import Chill
import XCTest
import SwiftUI
import UIKit

final class WelcomeViewSnapshotTests: XCTestCase {
    func testDisplaysSubheadlineInformingAboutAccess() {
        let hosting = UIHostingController(rootView: WelcomeView(viewModel: WelcomeViewModel()))
        hosting.loadViewIfNeeded()

        let labels = Self.collectLabels(in: hosting.view)
        let expectedSubheadline = "Account access opens soon; stay tuned for the full experience."
        XCTAssertTrue(labels.contains(expectedSubheadline), "WelcomeView should display the localized subheadline messaging")
    }

    func testButtonsRemainEnabledForTouchFeedback() {
        let hosting = UIHostingController(rootView: WelcomeView(viewModel: WelcomeViewModel()))
        hosting.loadViewIfNeeded()

        let buttons = Self.collectButtons(in: hosting.view)
        XCTAssertEqual(buttons.count, 2, "Expected two CTA buttons in the hierarchy")
        XCTAssertFalse(buttons.contains { !$0.isEnabled }, "Buttons should stay enabled even though actions are no-ops")
    }

    func testButtonsExposeAccessibilityHints() {
        let hosting = UIHostingController(rootView: WelcomeView(viewModel: WelcomeViewModel()))
        hosting.loadViewIfNeeded()

        let buttons = Self.collectButtons(in: hosting.view)
        let hints = buttons.compactMap(\.accessibilityHint)
        let expectedHint = "Authentication coming soon. Buttons are currently inactive."
        XCTAssertTrue(hints.contains(expectedHint), "VoiceOver hint should set expectation about inactive authentication")
    }

    private static func collectLabels(in view: UIView) -> [String] {
        var results: [String] = []
        if let label = view as? UILabel, let text = label.text {
            results.append(text)
        }
        for subview in view.subviews {
            results.append(contentsOf: collectLabels(in: subview))
        }
        return results
    }

    private static func collectButtons(in view: UIView) -> [UIButton] {
        var results: [UIButton] = []
        if let button = view as? UIButton {
            results.append(button)
        }
        for subview in view.subviews {
            results.append(contentsOf: collectButtons(in: subview))
        }
        return results
    }
}
