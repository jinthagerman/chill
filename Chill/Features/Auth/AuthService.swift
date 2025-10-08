import Combine
import Foundation
import Supabase

protocol AuthServiceType {
    var sessionPublisher: AnyPublisher<AuthSession?, Never> { get }
    var currentSession: AuthSession? { get }  // Added in: 006-add-a-profile
    func signUp(email: String, password: String, consent: Bool) async throws -> AuthSession
    func signIn(email: String, password: String) async throws -> AuthSession
    func signOut() async throws
    func requestPasswordReset(email: String) async throws
    func verifyResetCode(email: String, code: String, newPassword: String) async throws -> AuthSession
    func changePassword(currentPassword: String, newPassword: String) async throws  // Added in: 006-add-a-profile
}

enum AuthClientSignUpResult: Equatable {
    case session(AuthClientSession)
    case verificationRequired(email: String)
}

protocol AuthServiceClient {
    var currentSession: AuthClientSession? { get }
    var sessionUpdates: AsyncStream<AuthClientSession?> { get }
    func signUp(email: String, password: String, consent: Bool) async throws -> AuthClientSignUpResult
    func signIn(email: String, password: String) async throws -> AuthClientSession
    func signOut() async throws
    func sendPasswordReset(email: String) async throws
    func verifyOTP(email: String, token: String, newPassword: String) async throws -> AuthClientSession
}

struct AuthClientSession: Equatable {
    let userID: UUID
    let email: String
    let accessTokenExpiresAt: Date
    let refreshToken: String
    let isVerified: Bool
    let raw: Any?

    static func == (lhs: AuthClientSession, rhs: AuthClientSession) -> Bool {
        lhs.userID == rhs.userID &&
            lhs.email == rhs.email &&
            lhs.accessTokenExpiresAt == rhs.accessTokenExpiresAt &&
            lhs.refreshToken == rhs.refreshToken &&
            lhs.isVerified == rhs.isVerified
    }
}

struct AuthClientError: Error, Equatable {
    let status: Int
    let code: String?
    let message: String

    init(status: Int, code: String?, message: String) {
        self.status = status
        self.code = code
        self.message = message
    }
}

@MainActor
final class AuthService: AuthServiceType {
    private let client: AuthServiceClient
    private let sessionSubject: CurrentValueSubject<AuthSession?, Never>
    private var sessionUpdatesTask: Task<Void, Never>?

    init(client: AuthServiceClient) {
        self.client = client
        let initialSession = client.currentSession.map(AuthService.mapSession(_:))
        sessionSubject = CurrentValueSubject(initialSession)
        sessionUpdatesTask = Task { [weak self] in
            guard let self else { return }
            for await update in client.sessionUpdates {
                await MainActor.run {
                    let mapped = update.map(AuthService.mapSession(_:))
                    self.sessionSubject.send(mapped)
                }
            }
        }
    }

    var sessionPublisher: AnyPublisher<AuthSession?, Never> {
        sessionSubject.eraseToAnyPublisher()
    }

    var currentSession: AuthSession? {
        sessionSubject.value
    }

    func signUp(email: String, password: String, consent: Bool) async throws -> AuthSession {
        guard consent else { throw AuthError.unknown }
        do {
            let result = try await client.signUp(email: email, password: password, consent: consent)
            switch result {
            case let .session(session):
                let mapped = AuthService.mapSession(session)
                sessionSubject.send(mapped)
                return mapped
            case .verificationRequired:
                throw AuthError.emailUnverified
            }
        } catch {
            throw normalize(error)
        }
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        do {
            let session = try await client.signIn(email: email, password: password)
            let mapped = AuthService.mapSession(session)
            sessionSubject.send(mapped)
            return mapped
        } catch {
            throw normalize(error)
        }
    }

    func signOut() async throws {
        sessionSubject.send(nil)

        do {
            try await client.signOut()
        } catch {
            throw normalize(error)
        }
    }

    func requestPasswordReset(email: String) async throws {
        do {
            try await client.sendPasswordReset(email: email)
        } catch {
            throw normalize(error)
        }
    }

    func verifyResetCode(email: String, code: String, newPassword: String) async throws -> AuthSession {
        do {
            let session = try await client.verifyOTP(email: email, token: code, newPassword: newPassword)
            let mapped = AuthService.mapSession(session)
            sessionSubject.send(mapped)
            return mapped
        } catch {
            throw normalize(error)
        }
    }
    
    /// Change user password (requires current password verification)
    /// Added in: 006-add-a-profile
    func changePassword(currentPassword: String, newPassword: String) async throws {
        // Get current session
        guard let session = currentSession else {
            throw ProfileError.unauthorized
        }
        
        // Validate password length
        guard newPassword.count >= 8 else {
            throw ProfileError.passwordTooWeak
        }
        
        // Reauthenticate with current password to verify
        do {
            _ = try await client.signIn(email: session.email, password: currentPassword)
        } catch {
            // Reauthentication failed - current password is incorrect
            throw ProfileError.currentPasswordIncorrect
        }
        
        // Current password verified, now update to new password
        // Note: Supabase SDK doesn't have a direct password update method in the client protocol
        // We'll need to use the actual Supabase client for this
        // For now, throw a placeholder error - this will need to be connected to real Supabase client
        throw ProfileError.updateFailed
    }

    private static func mapSession(_ session: AuthClientSession) -> AuthSession {
        AuthSession(
            userID: session.userID,
            email: session.email,
            accessTokenExpiresAt: session.accessTokenExpiresAt,
            refreshToken: session.refreshToken,
            isVerified: session.isVerified,
            rawSupabaseData: session.raw
        )
    }

    private func normalize(_ error: Error) -> Error {
        if let authError = error as? AuthError {
            return authError
        }

        if let clientError = error as? AuthClientError {
            return mapClientError(clientError)
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .timedOut, .cannotFindHost, .cannotConnectToHost:
                return AuthError.networkUnavailable
            default:
                return AuthError.unknown
            }
        }

        return AuthError.unknown
    }

    private func mapClientError(_ error: AuthClientError) -> AuthError {
        if let code = error.code?.lowercased() {
            switch code {
            case "invalid_credentials":
                sessionSubject.send(nil)
                return .invalidCredentials
            case "email_not_confirmed", "email_not_verified":
                return .emailUnverified
            case "over_email_send_rate_limit", "over_request_rate_limit", "over_sms_send_rate_limit":
                return .rateLimited
            case "otp_expired", "otp_disabled", "otp_invalid":
                return .otpIncorrect
            case "user_already_exists":
                return .duplicateEmail
            case "session_not_found", "session_expired":
                sessionSubject.send(nil)
                return .invalidCredentials
            default:
                break
            }
        }

        switch error.status {
        case 401, 403:
            sessionSubject.send(nil)
            return .invalidCredentials
        case 429:
            return .rateLimited
        default:
            return .unknown
        }
    }

    deinit {
        sessionUpdatesTask?.cancel()
    }
}

final class SupabaseAuthClient: AuthServiceClient {
    private let auth: AuthClient
    private let configuration: AuthConfiguration
    private let sessionStream: AsyncStream<AuthClientSession?>
    private var sessionContinuation: AsyncStream<AuthClientSession?>.Continuation?
    private var authListenerTask: Task<Void, Never>?
    private var registration: (any AuthStateChangeListenerRegistration)?

    init(configuration: AuthConfiguration) {
        self.configuration = configuration
        let client = SupabaseClient(
            supabaseURL: configuration.supabaseURL,
            supabaseKey: configuration.supabaseAnonKey,
            options: SupabaseClientOptions(auth: .init(autoRefreshToken: true))
        )
        self.auth = client.auth

        var continuation: AsyncStream<AuthClientSession?>.Continuation?
        self.sessionStream = AsyncStream { cont in
            continuation = cont
        }
        self.sessionContinuation = continuation

        authListenerTask = Task { [weak self] in
            guard let self else { return }
            let registration = await auth.onAuthStateChange { [weak self] event, session in
                guard let self else { return }
                switch event {
                case .initialSession, .signedIn, .tokenRefreshed, .userUpdated, .mfaChallengeVerified:
                    let mapped = session.map(SupabaseAuthClient.mapSession(_:))
                    self.sessionContinuation?.yield(mapped)
                case .signedOut:
                    self.sessionContinuation?.yield(nil)
                case .passwordRecovery, .userDeleted:
                    break
                }
            }

            await MainActor.run {
                self.registration = registration
            }
        }
    }

    deinit {
        authListenerTask?.cancel()
        registration?.remove()
        sessionContinuation?.finish()
    }

    var currentSession: AuthClientSession? {
        guard let session = auth.currentSession else { return nil }
        return SupabaseAuthClient.mapSession(session)
    }

    var sessionUpdates: AsyncStream<AuthClientSession?> {
        sessionStream
    }

    func signUp(email: String, password: String, consent: Bool) async throws -> AuthClientSignUpResult {
        do {
            let response = try await auth.signUp(email: email, password: password)
            switch response {
            case let .session(session):
                return .session(SupabaseAuthClient.mapSession(session))
            case let .user(user):
                return .verificationRequired(email: user.email ?? email)
            }
        } catch {
            throw wrap(error)
        }
    }

    func signIn(email: String, password: String) async throws -> AuthClientSession {
        do {
            let session = try await auth.signIn(email: email, password: password)
            return SupabaseAuthClient.mapSession(session)
        } catch {
            throw wrap(error)
        }
    }

    func signOut() async throws {
        do {
            try await auth.signOut()
        } catch {
            throw wrap(error)
        }
    }

    func sendPasswordReset(email: String) async throws {
        do {
            try await auth.resetPasswordForEmail(email)
        } catch {
            throw wrap(error)
        }
    }

    func verifyOTP(email: String, token: String, newPassword: String) async throws -> AuthClientSession {
        do {
            let response = try await auth.verifyOTP(
                email: email,
                token: token,
                type: .recovery
            )
            switch response {
            case let .session(session):
                return SupabaseAuthClient.mapSession(session)
            case .user:
                throw AuthClientError(status: 202, code: Supabase.ErrorCode.emailNotConfirmed.rawValue, message: "Verification still pending")
            }
        } catch {
            throw wrap(error)
        }
    }

    private static func mapSession(_ session: Session) -> AuthClientSession {
        AuthClientSession(
            userID: session.user.id,
            email: session.user.email ?? "",
            accessTokenExpiresAt: Date(timeIntervalSince1970: session.expiresAt),
            refreshToken: session.refreshToken,
            isVerified: (session.user.emailConfirmedAt ?? session.user.confirmedAt) != nil,
            raw: session
        )
    }

    private func wrap(_ error: Error) -> Error {
        if let authError = error as? Supabase.AuthError {
            switch authError {
            case let .api(message, errorCode, _, response):
                return AuthClientError(status: response.statusCode, code: errorCode.rawValue, message: message)
            case let .weakPassword(message, _):
                return AuthClientError(status: 400, code: Supabase.ErrorCode.weakPassword.rawValue, message: message)
            case .sessionMissing:
                return AuthClientError(status: 401, code: Supabase.ErrorCode.sessionNotFound.rawValue, message: authError.message)
            case let .pkceGrantCodeExchange(message, _, code):
                return AuthClientError(status: 400, code: code ?? Supabase.ErrorCode.badCodeVerifier.rawValue, message: message)
            case .implicitGrantRedirect(let message):
                return AuthClientError(status: 400, code: Supabase.ErrorCode.badOAuthCallback.rawValue, message: message)
            default:
                return AuthClientError(status: 400, code: authError.errorCode.rawValue, message: authError.message)
            }
        }

        if let urlError = error as? URLError {
            return AuthClientError(status: urlError.errorCode, code: nil, message: urlError.localizedDescription)
        }

        return error
    }
}

extension AuthService {
    static func live(configuration: AuthConfiguration) -> AuthService {
        AuthService(client: SupabaseAuthClient(configuration: configuration))
    }
}
