import Foundation
import Combine
import SwiftUI

final class WelcomeViewModel: ObservableObject {
    @Published private(set) var content: WelcomeContent
    @Published private(set) var buttonState: ButtonState
    @Published var isAnimatingEntry: Bool

    private let onLoginSelected: (() -> Void)?
    private let onSignupSelected: (() -> Void)?

    init(
        content: WelcomeContent = .default,
        buttonState: ButtonState = .inactive,
        isAnimatingEntry: Bool = false,
        onLoginSelected: (() -> Void)? = nil,
        onSignupSelected: (() -> Void)? = nil
    ) {
        self.content = content
        self.buttonState = buttonState
        self.isAnimatingEntry = isAnimatingEntry
        self.onLoginSelected = onLoginSelected
        self.onSignupSelected = onSignupSelected
    }

    var primaryButtons: [WelcomeButton] {
        [
            button(for: .login),
            button(for: .signup)
        ]
    }

    var ctaAccessibilityHint: LocalizedStringKey {
        content.ctaAccessibilityHint
    }

    func beginAnimationsIfNeeded() {
        guard isAnimatingEntry == false else { return }
        isAnimatingEntry = true
    }

    func handleTap(for role: WelcomeButton.Role) {
        guard isRoleActive(role) else { return }
        switch role {
        case .login:
            onLoginSelected?()
        case .signup:
            onSignupSelected?()
        }
    }

    func updateButtonState(_ state: ButtonState) {
        buttonState = state
    }

    private func isRoleActive(_ role: WelcomeButton.Role) -> Bool {
        switch buttonState {
        case .inactive:
            return false
        case let .active(loginPermitted, signupPermitted):
            switch role {
            case .login:
                return loginPermitted
            case .signup:
                return signupPermitted
            }
        }
    }

    private func button(for role: WelcomeButton.Role) -> WelcomeButton {
        WelcomeButton(
            title: role.titleKey,
            role: role,
            isActive: isRoleActive(role)
        )
    }
}
