import Foundation
import os

struct AuthAnalytics {
    private let handler: (AuthEventPayload) -> Void

    init(handler: @escaping (AuthEventPayload) -> Void) {
        self.handler = handler
    }

    func track(_ payload: AuthEventPayload) {
        handler(payload)
    }

    static let noop = AuthAnalytics { _ in }

    static func live(logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.bitcrank.Chill", category: "Auth")) -> AuthAnalytics {
        return AuthAnalytics { payload in
            logger.log(
                "event=\(payload.eventType.rawValue, privacy: .public) result=\(payload.result.rawValue, privacy: .public) error=\(payload.supabaseErrorCode ?? "none", privacy: .public) latencyMs=\(payload.latencyMs, privacy: .public) network=\(payload.networkStatus.rawValue, privacy: .public) phase=\(payload.phase?.rawValue ?? "n/a", privacy: .public)"
            )
        }
    }
}
