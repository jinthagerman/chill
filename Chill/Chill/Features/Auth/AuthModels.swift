import Foundation

struct AuthSession: Equatable {
    let userID: UUID
    let email: String
    let accessTokenExpiresAt: Date
    let refreshToken: String
    let isVerified: Bool
    let rawSupabaseData: Any?

    init(
        userID: UUID,
        email: String,
        accessTokenExpiresAt: Date,
        refreshToken: String,
        isVerified: Bool,
        rawSupabaseData: Any? = nil
    ) {
        self.userID = userID
        self.email = email
        self.accessTokenExpiresAt = accessTokenExpiresAt
        self.refreshToken = refreshToken
        self.isVerified = isVerified
        self.rawSupabaseData = rawSupabaseData
    }

    static func == (lhs: AuthSession, rhs: AuthSession) -> Bool {
        lhs.userID == rhs.userID &&
            lhs.email == rhs.email &&
            lhs.accessTokenExpiresAt == rhs.accessTokenExpiresAt &&
            lhs.refreshToken == rhs.refreshToken &&
            lhs.isVerified == rhs.isVerified
    }
}

enum AuthMode: Equatable, Hashable {
    case login
    case signup(consentAccepted: Bool)
    case resetRequest
    case resetVerify(pendingEmail: String)
}

enum AuthError: Error, Equatable {
    case networkUnavailable
    case invalidCredentials
    case emailUnverified
    case rateLimited
    case otpIncorrect
    case unknown
}

enum AuthEventType: String {
    case signUp = "auth_sign_up"
    case signIn = "auth_sign_in"
    case passwordReset = "auth_password_reset"
}

enum AuthEventResult: String {
    case success
    case failure
}

enum AuthPasswordResetPhase: String {
    case request
    case verify
}

enum NetworkReachability: String {
    case wifi
    case cellular
    case offline
}

struct AuthEventPayload {
    let eventType: AuthEventType
    let result: AuthEventResult
    let supabaseErrorCode: String?
    let latencyMs: Int
    let networkStatus: NetworkReachability
    let phase: AuthPasswordResetPhase?

    init(
        eventType: AuthEventType,
        result: AuthEventResult,
        supabaseErrorCode: String? = nil,
        latencyMs: Int,
        networkStatus: NetworkReachability,
        phase: AuthPasswordResetPhase? = nil
    ) {
        self.eventType = eventType
        self.result = result
        self.supabaseErrorCode = supabaseErrorCode
        self.latencyMs = latencyMs
        self.networkStatus = networkStatus
        self.phase = phase
    }
}

struct AuthBanner: Equatable {
    enum BannerType: Equatable {
        case success
        case error
        case info
    }

    let type: BannerType
    let message: String
    let retry: (() -> Void)?

    init(type: BannerType, message: String, retry: (() -> Void)? = nil) {
        self.type = type
        self.message = message
        self.retry = retry
    }

    // Custom Equatable conformance: ignore the non-Equatable closure `retry`.
    static func == (lhs: AuthBanner, rhs: AuthBanner) -> Bool {
        lhs.type == rhs.type && lhs.message == rhs.message
    }
}
