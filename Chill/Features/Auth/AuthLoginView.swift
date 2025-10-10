import SwiftUI

/// Dedicated login screen for returning users
/// Added in: 005-split-login-and
struct AuthLoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @FocusState private var focusedField: AuthField?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    
                    if let banner = viewModel.statusBanner {
                        BannerView(banner: banner)
                    }
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.body)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .accessibilityIdentifier("auth_error_message")
                    }
                    
                    formFields
                    submitButton
                    forgotPasswordButton
                }
                .padding(.vertical, 32)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.navigateBack()
                        // Note: Coordinator should handle actual navigation back to Welcome
                    } label: {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sign In")
                .font(.largeTitle.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            Text("Welcome back to Chill")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var formFields: some View {
        VStack(spacing: 16) {
            TextField("Email address", text: $viewModel.email)
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
                .accessibilityIdentifier("auth_email")
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            
            SecureField("Password", text: $viewModel.password)
                .textContentType(.password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .focused($focusedField, equals: .password)
                .submitLabel(.done)
                .onSubmit { 
                    focusedField = nil
                    Task { await viewModel.submit() }
                }
                .accessibilityIdentifier("auth_password")
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
        }
    }
    
    private var submitButton: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            Group {
                if viewModel.isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text("Log In")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(viewModel.canSubmit ? Color.accentColor : Color.accentColor.opacity(0.4))
        .foregroundColor(.white)
        .cornerRadius(12)
        .disabled(viewModel.isProcessing || !viewModel.canSubmit)
        .accessibilityIdentifier("auth_submit")
        .accessibilityLabel("Log In")
    }
    
    private var forgotPasswordButton: some View {
        Button("Forgot password?") {
            viewModel.navigateToResetRequest()
        }
        .accessibilityIdentifier("auth_forgot_password")
    }
}
