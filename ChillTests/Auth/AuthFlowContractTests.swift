import XCTest
@testable import Chill

@MainActor
final class AuthFlowContractTests: XCTestCase {
    private var service: AuthServiceStub!
    private var authenticatedCount: Int!

    override func setUp() async throws {
        try await super.setUp()
        service = AuthServiceStub()
        authenticatedCount = 0
    }

    override func tearDown() async throws {
        service = nil
        authenticatedCount = nil
        try await super.tearDown()
    }

    func testSignupWithPendingVerificationShowsAwaitState() async {
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
            initialMode: .signup(consentAccepted: true),
            networkStatus: .wifi,
            analytics: .noop
        ) { [weak self] in
            self?.authenticatedCount += 1
        }

        viewModel.email = "signup@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"

        await viewModel.submit()

        XCTAssertEqual(service.signUpCallCount, 1)
        XCTAssertEqual(authenticatedCount, 0, "Should not auto-route until verification completes")
        XCTAssertEqual(viewModel.mode, .signup(consentAccepted: true))
        XCTAssertEqual(viewModel.statusBanner?.type, .info)
        XCTAssertEqual(viewModel.statusBanner?.message, "Check your email to verify your account.")
    }

    func testExistingSessionOnLaunchRoutesToSavedLinks() async {
        let viewModel = AuthViewModel(
            service: service,
            initialMode: .login,
            networkStatus: .wifi,
            analytics: .noop
        ) { [weak self] in
            self?.authenticatedCount += 1
        }

        let session = AuthSession(
            userID: UUID(),
            email: "existing@example.com",
            accessTokenExpiresAt: Date().addingTimeInterval(3600),
            refreshToken: "refresh",
            isVerified: true
        )

        await viewModel.handleSessionChange(session)

        XCTAssertEqual(viewModel.session?.email, session.email)
        XCTAssertEqual(authenticatedCount, 1)
    }

    func testPasswordResetFlowMatchesContract() async {
        service.passwordResetResult = .success(())
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
            analytics: .noop
        ) { [weak self] in
            self?.authenticatedCount += 1
        }

        viewModel.email = "reset@example.com"

        await viewModel.startReset()

        guard case let .resetVerify(pendingEmail) = viewModel.mode else {
            return XCTFail("Expected reset verify mode")
        }
        XCTAssertEqual(pendingEmail, "reset@example.com")
        XCTAssertEqual(viewModel.statusBanner?.type, .info)
        XCTAssertEqual(viewModel.statusBanner?.message, "Enter the 6-digit code sent to your email.")

        viewModel.otpCode = "123456"
        viewModel.password = "newpassword123"

        await viewModel.confirmReset()

        XCTAssertEqual(service.verifyResetCallCount, 1)
        XCTAssertEqual(authenticatedCount, 1)
        XCTAssertEqual(viewModel.mode, .login)
    }
}
