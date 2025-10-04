import XCTest
@testable import Chill

@MainActor
final class AuthViewModelTests: XCTestCase {
    private var service: AuthServiceStub!
    private var onAuthenticatedCallCount: Int!

    override func setUp() async throws {
        try await super.setUp()
        service = AuthServiceStub()
        onAuthenticatedCallCount = 0
    }

    override func tearDown() async throws {
        service = nil
        onAuthenticatedCallCount = nil
        try await super.tearDown()
    }

    func testLoginSuccessRoutesToSavedLinks() async {
        let session = AuthSession(
            userID: UUID(),
            email: "login@example.com",
            accessTokenExpiresAt: Date().addingTimeInterval(3600),
            refreshToken: "refresh",
            isVerified: true
        )
        service.signInResult = .success(session)

        let viewModel = AuthViewModel(
            service: service,
            initialMode: .login,
            networkStatus: .wifi,
            analytics: .noop
        ) { [weak self] in
            self?.onAuthenticatedCallCount += 1
        }

        viewModel.email = session.email
        viewModel.password = "password123"

        await viewModel.submit()

        XCTAssertEqual(service.signInCallCount, 1)
        XCTAssertEqual(viewModel.session?.userID, session.userID)
        XCTAssertEqual(onAuthenticatedCallCount, 1)
    }

    func testSignupValidationRequiresConsentAndNetwork() {
        service.signUpResult = .success(
            AuthSession(
                userID: UUID(),
                email: "signup@example.com",
                accessTokenExpiresAt: Date().addingTimeInterval(3600),
                refreshToken: "refresh",
                isVerified: false
            )
        )

        let viewModel = AuthViewModel(
            service: service,
            initialMode: .signup(consentAccepted: false),
            networkStatus: .wifi,
            analytics: .noop,
            onAuthenticated: { }
        )

        viewModel.email = "signup@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"

        XCTAssertFalse(viewModel.canSubmit, "Consent required")

        viewModel.updateMode(.signup(consentAccepted: true))
        XCTAssertTrue(viewModel.canSubmit, "Should submit when consent granted and network online")

        viewModel.updateNetworkStatus(.offline)
        XCTAssertFalse(viewModel.canSubmit, "Offline state should block submission")
    }

    func testPasswordResetFlowTransitionsToVerification() async {
        service.passwordResetResult = .success(() )
        service.verifyResetResult = .success(
            AuthSession(
                userID: UUID(),
                email: "reset@example.com",
                accessTokenExpiresAt: Date().addingTimeInterval(3600),
                refreshToken: "refresh",
                isVerified: true
            )
        )

        let viewModel = AuthViewModel(
            service: service,
            initialMode: .resetRequest,
            networkStatus: .wifi,
            analytics: .noop,
            onAuthenticated: { }
        )

        viewModel.email = "reset@example.com"

        await viewModel.startReset()

        guard case let .resetVerify(pendingEmail) = viewModel.mode else {
            return XCTFail("Expected reset verify mode")
        }
        XCTAssertEqual(pendingEmail, "reset@example.com")

        viewModel.otpCode = "123456"
        viewModel.password = "newpass123"

        await viewModel.confirmReset()

        XCTAssertEqual(service.verifyResetCallCount, 1)
        XCTAssertEqual(viewModel.mode, .login)
    }
}
