import XCTest
@testable import Chill

final class AuthServiceTests: XCTestCase {
    private var client: FakeAuthClient!
    private var service: AuthService!

    override func setUp() {
        super.setUp()
        client = FakeAuthClient()
        service = AuthService(client: client)
    }

    override func tearDown() {
        client = nil
        service = nil
        super.tearDown()
    }

    func testSignUpPublishesSessionOnSuccess() async throws {
        let expectedSession = AuthClientSession(
            userID: UUID(),
            email: "user@example.com",
            accessTokenExpiresAt: Date().addingTimeInterval(3600),
            refreshToken: "refresh-token",
            isVerified: true,
            raw: nil
        )
        client.signUpStub = .success(.session(expectedSession))

        let session = try await service.signUp(email: "user@example.com", password: "password123", consent: true)

        XCTAssertEqual(session.email, expectedSession.email)
        XCTAssertEqual(service.currentSession?.userID, expectedSession.userID)
        XCTAssertEqual(client.lastSignUpPayload?.consent, true)
    }

    func testSignInMapsInvalidCredentialsError() async {
        client.signInStub = .failure(AuthClientError(status: 400, code: "invalid_credentials", message: "Invalid login"))

        do {
            _ = try await service.signIn(email: "user@example.com", password: "wrong")
            XCTFail("Expected invalid credentials error")
        } catch {
            XCTAssertEqual(error as? AuthError, .invalidCredentials)
        }
    }

    func testSignUpRequiresVerificationThrowsEmailUnverified() async {
        client.signUpStub = .success(.verificationRequired(email: "user@example.com"))

        do {
            _ = try await service.signUp(email: "user@example.com", password: "password123", consent: true)
            XCTFail("Expected email unverified error")
        } catch {
            XCTAssertEqual(error as? AuthError, .emailUnverified)
        }
    }

    func testSignOutClearsSession() async throws {
        let existingSession = AuthClientSession(
            userID: UUID(),
            email: "existing@example.com",
            accessTokenExpiresAt: Date().addingTimeInterval(3600),
            refreshToken: "token",
            isVerified: true,
            raw: nil
        )
        client.currentSession = existingSession
        service = AuthService(client: client)
        client.signOutStub = .success(())

        try await service.signOut()

        XCTAssertNil(service.currentSession)
        XCTAssertTrue(client.didSignOut)
    }

    func testPasswordResetMapsRateLimitError() async {
        client.passwordResetStub = .failure(AuthClientError(status: 429, code: "over_email_send_rate_limit", message: "Rate limited"))

        do {
            try await service.requestPasswordReset(email: "user@example.com")
            XCTFail("Expected rate limited error")
        } catch {
            XCTAssertEqual(error as? AuthError, .rateLimited)
        }
    }

    func testVerifyResetCodeMapsOtpError() async {
        client.verifyOTPStub = .failure(AuthClientError(status: 400, code: "otp_expired", message: "OTP expired"))

        do {
            _ = try await service.verifyResetCode(email: "user@example.com", code: "123456", newPassword: "freshpass")
            XCTFail("Expected OTP error")
        } catch {
            XCTAssertEqual(error as? AuthError, .otpIncorrect)
        }
    }
}

private final class FakeAuthClient: AuthServiceClient {
    struct SignUpPayload {
        let email: String
        let password: String
        let consent: Bool
    }

    struct SignInPayload {
        let email: String
        let password: String
    }

    var currentSession: AuthClientSession?
    private(set) var didSignOut = false
    private(set) var continuation: AsyncStream<AuthClientSession?>.Continuation?

    var signUpStub: Result<AuthClientSignUpResult, Error>?
    var signInStub: Result<AuthClientSession, Error>?
    var signOutStub: Result<Void, Error>?
    var passwordResetStub: Result<Void, Error>?
    var verifyOTPStub: Result<AuthClientSession, Error>?

    private(set) var lastSignUpPayload: SignUpPayload?
    private(set) var lastSignInPayload: SignInPayload?

    lazy var sessionUpdates: AsyncStream<AuthClientSession?> = {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }()

    func signUp(email: String, password: String, consent: Bool) async throws -> AuthClientSignUpResult {
        lastSignUpPayload = SignUpPayload(email: email, password: password, consent: consent)
        guard let result = signUpStub else {
            throw AuthClientError(status: 500, code: nil, message: "Missing stub")
        }
        return try result.get()
    }

    func signIn(email: String, password: String) async throws -> AuthClientSession {
        lastSignInPayload = SignInPayload(email: email, password: password)
        guard let result = signInStub else {
            throw AuthClientError(status: 500, code: nil, message: "Missing stub")
        }
        return try result.get()
    }

    func signOut() async throws {
        didSignOut = true
        guard let result = signOutStub else {
            throw AuthClientError(status: 500, code: nil, message: "Missing stub")
        }
        _ = try result.get()
        currentSession = nil
        continuation?.yield(nil)
    }

    func sendPasswordReset(email: String) async throws {
        guard let result = passwordResetStub else {
            throw AuthClientError(status: 500, code: nil, message: "Missing stub")
        }
        _ = try result.get()
    }

    func verifyOTP(email: String, token: String, newPassword: String) async throws -> AuthClientSession {
        guard let result = verifyOTPStub else {
            throw AuthClientError(status: 500, code: nil, message: "Missing stub")
        }
        return try result.get()
    }
}
