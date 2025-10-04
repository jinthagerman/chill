import Foundation
import os

struct AuthAnalytics: Sendable {
    private let handler: @Sendable (AuthEventPayload) -> Void

    nonisolated init(handler: @escaping @Sendable (AuthEventPayload) -> Void) {
        self.handler = handler
    }

    func track(_ payload: AuthEventPayload) {
        handler(payload)
    }

    nonisolated static let noop = AuthAnalytics { _ in }

    nonisolated static func live(logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.bitcrank.Chill", category: "Auth")) -> AuthAnalytics {
        return AuthAnalytics { payload in
            logger.log(
                "event=\(payload.eventType.rawValue, privacy: .public) result=\(payload.result.rawValue, privacy: .public) error=\(payload.supabaseErrorCode ?? "none", privacy: .public) latencyMs=\(payload.latencyMs, privacy: .public) network=\(payload.networkStatus.rawValue, privacy: .public) phase=\(payload.phase?.rawValue ?? "n/a", privacy: .public)"
            )
        }
    }
}
