import Combine
import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var mode: AuthMode
    @Published var email: String
    @Published var password: String
    @Published var confirmPassword: String
    @Published var otpCode: String
    @Published var isProcessing: Bool
    @Published var errorMessage: String?
    @Published private(set) var session: AuthSession?
    @Published var statusBanner: AuthBanner?

    private let service: AuthServiceType
    private let onAuthenticated: () -> Void
    private var networkStatus: NetworkReachability
    private let analytics: AuthAnalytics
    private var cancellables = Set<AnyCancellable>()
    private var hasRoutedToSavedLinks = false

    init(
        service: AuthServiceType,
        initialMode: AuthMode = .login,
        networkStatus: NetworkReachability = .wifi,
        analytics: AuthAnalytics = .live(),
        onAuthenticated: @escaping () -> Void = {}
    ) {
        self.service = service
        self.mode = initialMode
        self.email = ""
        self.password = ""
        self.confirmPassword = ""
        self.otpCode = ""
        self.isProcessing = false
        self.errorMessage = nil
        self.statusBanner = nil
        self.networkStatus = networkStatus
        self.analytics = analytics
        self.onAuthenticated = onAuthenticated
        self.session = nil

        service.sessionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                Task { [weak self] in
                    await self?.handleSessionChange(session)
                }
            }
            .store(in: &cancellables)
    }

    var canSubmit: Bool {
        guard isProcessing == false else { return false }
        guard networkStatus != .offline else { return false }

        switch mode {
        case .login:
            return email.isValidEmail && password.isNotEmpty
        case let .signup(consentAccepted):
            return consentAccepted && email.isValidEmail && password.isNotEmpty && password == confirmPassword
        case .resetRequest:
            return email.isValidEmail
        case .resetVerify:
            return otpCode.count >= 6 && password.isNotEmpty
        }
    }

    var ctaLabel: String {
        switch mode {
        case .login:
            return "Log In"
        case .signup:
            return "Create Account"
        case .resetRequest:
            return "Send Reset Email"
        case .resetVerify:
            return "Verify Code"
        }
    }

    func submit() async {
        errorMessage = nil
        statusBanner = nil

        guard canSubmit else {
            if networkStatus == .offline {
                statusBanner = AuthBanner(type: .info, message: "You're offline. Try again once you're connected.")
            }
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        switch mode {
        case .login:
            await performLogin()
        case let .signup(consentAccepted):
            await performSignup(consentAccepted: consentAccepted)
        case .resetRequest:
            await startReset()
        case .resetVerify:
            await confirmReset()
        }
    }

    func startReset() async {
        errorMessage = nil
        statusBanner = nil

        guard email.isValidEmail else {
            errorMessage = "Enter a valid email."
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        let start = Date()
        do {
            try await service.requestPasswordReset(email: email)
            statusBanner = AuthBanner(type: .info, message: "Enter the 6-digit code sent to your email.")
            mode = .resetVerify(pendingEmail: email)
            recordAnalytics(
                event: .passwordReset,
                phase: .request,
                result: .success,
                error: nil,
                startedAt: start
            )
        } catch {
            errorMessage = message(for: error)
            recordAnalytics(
                event: .passwordReset,
                phase: .request,
                result: .failure,
                error: error,
                startedAt: start
            )
        }
    }

    func confirmReset() async {
        errorMessage = nil
        statusBanner = nil

        guard case let .resetVerify(pendingEmail) = mode else {
            errorMessage = "Reset flow unavailable."
            return
        }

        guard otpCode.count >= 6 else {
            errorMessage = "Enter the 6-digit code from your email."
            return
        }

        guard password.isNotEmpty else {
            errorMessage = "Create a new password to continue."
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        let start = Date()
        do {
            let session = try await service.verifyResetCode(email: pendingEmail, code: otpCode, newPassword: password)
            await handleSessionChange(session)
            mode = .login
            statusBanner = nil
            recordAnalytics(
                event: .passwordReset,
                phase: .verify,
                result: .success,
                error: nil,
                startedAt: start
            )
        } catch {
            errorMessage = message(for: error)
            recordAnalytics(
                event: .passwordReset,
                phase: .verify,
                result: .failure,
                error: error,
                startedAt: start
            )
        }
    }

    func handleSessionChange(_ session: AuthSession?) async {
        self.session = session
        guard let session else {
            hasRoutedToSavedLinks = false
            return
        }

        statusBanner = nil
        errorMessage = nil

        if hasRoutedToSavedLinks == false {
            hasRoutedToSavedLinks = true
            onAuthenticated()
        }
    }

    func updateMode(_ mode: AuthMode) {
        self.mode = mode
        statusBanner = nil
        errorMessage = nil
    }

    func updateNetworkStatus(_ status: NetworkReachability) {
        networkStatus = status
        if status == .offline {
            statusBanner = AuthBanner(type: .info, message: "You're offline. Saved credentials remain intact until you reconnect.")
        } else if statusBanner?.message.hasPrefix("You're offline") == true {
            statusBanner = nil
        }
    }

    private func performLogin() async {
        let start = Date()
        do {
            let session = try await service.signIn(email: email, password: password)
            recordAnalytics(
                event: .signIn,
                phase: nil,
                result: .success,
                error: nil,
                startedAt: start
            )
            await handleSessionChange(session)
        } catch {
            recordAnalytics(
                event: .signIn,
                phase: nil,
                result: .failure,
                error: error,
                startedAt: start
            )
            errorMessage = message(for: error)
        }
    }

    private func performSignup(consentAccepted: Bool) async {
        guard consentAccepted else {
            errorMessage = "You must accept the terms to continue."
            return
        }

        let start = Date()
        do {
            let session = try await service.signUp(email: email, password: password, consent: consentAccepted)
            recordAnalytics(
                event: .signUp,
                phase: nil,
                result: .success,
                error: nil,
                startedAt: start
            )
            if session.isVerified {
                await handleSessionChange(session)
            } else {
                statusBanner = AuthBanner(type: .info, message: "Check your email to verify your account.")
            }
        } catch {
            if case AuthError.emailUnverified = error {
                statusBanner = AuthBanner(type: .info, message: "Check your email to verify your account.")
            } else {
                errorMessage = message(for: error)
            }
            recordAnalytics(
                event: .signUp,
                phase: nil,
                result: .failure,
                error: error,
                startedAt: start
            )
        }
    }

    private func message(for error: Error) -> String {
        switch error {
        case AuthError.networkUnavailable:
            return "We can't reach the server. Check your connection and try again."
        case AuthError.invalidCredentials:
            return "That email or password looks incorrect."
        case AuthError.emailUnverified:
            return "Verify your email before signing in."
        case AuthError.rateLimited:
            return "Too many attempts. Please try again shortly."
        case AuthError.otpIncorrect:
            return "That code isn't right. Double-check and try again."
        default:
            return "Something went wrong. Please try again."
        }
    }

    private func recordAnalytics(
        event: AuthEventType,
        phase: AuthPasswordResetPhase?,
        result: AuthEventResult,
        error: Error?,
        startedAt: Date
    ) {
        let latency = max(Int(Date().timeIntervalSince(startedAt) * 1000), 0)
        let payload = AuthEventPayload(
            eventType: event,
            result: result,
            supabaseErrorCode: analyticsCode(from: error),
            latencyMs: latency,
            networkStatus: networkStatus,
            phase: phase
        )
        analytics.track(payload)
    }

    private func analyticsCode(from error: Error?) -> String? {
        guard let authError = error as? AuthError else { return nil }
        switch authError {
        case .networkUnavailable:
            return "network_unavailable"
        case .invalidCredentials:
            return "invalid_credentials"
        case .emailUnverified:
            return "email_unverified"
        case .rateLimited:
            return "rate_limited"
        case .otpIncorrect:
            return "otp_incorrect"
        case .unknown:
            return "unknown"
        }
    }
}

 private extension String {
    var isNotEmpty: Bool { isEmpty == false }
    var isValidEmail: Bool { contains("@") && contains(".") }
 }
