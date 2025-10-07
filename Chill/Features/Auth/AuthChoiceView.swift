import SwiftUI

/// Initial choice screen presenting login and signup options
/// Added in: 005-split-login-and
struct AuthChoiceView: View {
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                header
                
                if let banner = viewModel.statusBanner {
                    BannerView(banner: banner)
                }
                
                VStack(spacing: 16) {
                    signInButton
                    createAccountButton
                }
            }
            .padding(.vertical, 48)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Welcome to Chill")
                .font(.largeTitle.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            
            Text("Watch and save videos for later")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var signInButton: some View {
        Button {
            viewModel.navigateToLogin()
        } label: {
            Text("Sign In")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .accessibilityIdentifier("auth_choice_signin")
        .accessibilityLabel("Sign In")
        .accessibilityHint("Navigate to login screen")
    }
    
    private var createAccountButton: some View {
        Button {
            viewModel.navigateToSignup()
        } label: {
            Text("Create Account")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(12)
        }
        .accessibilityIdentifier("auth_choice_signup")
        .accessibilityLabel("Create Account")
        .accessibilityHint("Navigate to signup screen")
    }
}
