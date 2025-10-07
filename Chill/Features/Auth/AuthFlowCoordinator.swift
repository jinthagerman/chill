import SwiftUI

/// Coordinator view that renders the appropriate auth screen based on navigation state
/// Added in: 005-split-login-and
struct AuthFlowCoordinator: View {
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        switch viewModel.navigationState {
        case .choice:
            AuthChoiceView(viewModel: viewModel)
        case .login:
            AuthLoginView(viewModel: viewModel)
        case .signup:
            AuthSignupView(viewModel: viewModel)
        case .resetRequest, .resetVerify:
            // Fallback to existing AuthView for password reset flows
            // TODO: Create dedicated reset views in future iterations
            AuthView(viewModel: viewModel)
        }
    }
}
