@testable import Chill
import XCTest

final class WelcomeViewModelTests: XCTestCase {
    func testPrimaryButtonsExposeLoginAndSignupRoles() {
        let subject = WelcomeViewModel()
        let roles = subject.primaryButtons.map(\.role)
        XCTAssertEqual(roles, [.login, .signup], "Expected login and signup buttons in order")
    }

    func testButtonsAreInactiveByDefault() {
        let subject = WelcomeViewModel()
        XCTAssertTrue(subject.primaryButtons.allSatisfy { !$0.isActive }, "Buttons remain inactive until auth enabled")
    }
}
