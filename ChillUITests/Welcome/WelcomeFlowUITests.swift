import XCTest

final class WelcomeFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testWelcomeScreenShowsComingSoonMessaging() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--enable-welcome-experience")
        app.launch()

        let loginButton = app.buttons["welcomeLoginButton"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 5), "Log In CTA should be visible")
        let signupButton = app.buttons["welcomeSignupButton"]
        XCTAssertTrue(signupButton.exists, "Sign Up CTA should be visible")
        let subheadline = app.staticTexts["welcomeSubheadline"]
        XCTAssertTrue(subheadline.exists, "Subheadline should communicate upcoming authentication availability")

        loginButton.tap()
        XCTAssertTrue(loginButton.exists, "Tapping button should keep user on welcome screen")
    }
}
