import Combine
@testable import Chill

@MainActor
final class AuthServiceStub: AuthServiceType {
    enum StubError: Error {
        case missing
    }

    private let subject = CurrentValueSubject<AuthSession?, Never>(nil)

    var sessionPublisher: AnyPublisher<AuthSession?, Never> {
        subject.eraseToAnyPublisher()
    }

    var signUpResult: Result<AuthSession, Error>?
    var signInResult: Result<AuthSession, Error>?
    var signOutResult: Result<Void, Error>?
    var passwordResetResult: Result<Void, Error>?
    var verifyResetResult: Result<AuthSession, Error>?

    private(set) var signInCallCount = 0
    private(set) var signUpCallCount = 0
    private(set) var signOutCallCount = 0
    private(set) var passwordResetCallCount = 0
    private(set) var verifyResetCallCount = 0

    func signUp(email: String, password: String, consent: Bool) async throws -> AuthSession {
        signUpCallCount += 1
        guard let result = signUpResult else { throw StubError.missing }
        let session = try result.get()
        subject.send(session)
        return session
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        signInCallCount += 1
        guard let result = signInResult else { throw StubError.missing }
        let session = try result.get()
        subject.send(session)
        return session
    }

    func signOut() async throws {
        signOutCallCount += 1
        guard let result = signOutResult else { throw StubError.missing }
        _ = try result.get()
        subject.send(nil)
    }

    func requestPasswordReset(email: String) async throws {
        passwordResetCallCount += 1
        guard let result = passwordResetResult else { throw StubError.missing }
        _ = try result.get()
    }

    func verifyResetCode(email: String, code: String, newPassword: String) async throws -> AuthSession {
        verifyResetCallCount += 1
        guard let result = verifyResetResult else { throw StubError.missing }
        let session = try result.get()
        subject.send(session)
        return session
    }
}
