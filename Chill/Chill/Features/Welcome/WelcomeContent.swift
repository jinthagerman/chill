import SwiftUI

struct WelcomeContent {
    var headline: LocalizedStringKey
    var subheadline: LocalizedStringKey
    var backgroundImageName: String?
    var ctaAccessibilityHint: LocalizedStringKey

    static var `default`: WelcomeContent {
        WelcomeContent(
            headline: LocalizedStringKey("welcome_headline"),
            subheadline: LocalizedStringKey("welcome_subheadline"),
            backgroundImageName: "WelcomeBackground",
            ctaAccessibilityHint: LocalizedStringKey("welcome_cta_accessibility_hint")
        )
    }
}

struct WelcomeButton: Identifiable, Equatable {
    enum Role: Equatable {
        case login
        case signup

        var titleKey: LocalizedStringKey {
            switch self {
            case .login:
                return LocalizedStringKey("welcome_button_login")
            case .signup:
                return LocalizedStringKey("welcome_button_signup")
            }
        }
    }

    let id: UUID
    let title: LocalizedStringKey
    let role: Role
    let isActive: Bool

    init(id: UUID = UUID(), title: LocalizedStringKey, role: Role, isActive: Bool) {
        self.id = id
        self.title = title
        self.role = role
        self.isActive = isActive
    }
}

enum ButtonState: Equatable {
    case inactive
    case active(loginPermitted: Bool, signupPermitted: Bool)
}
