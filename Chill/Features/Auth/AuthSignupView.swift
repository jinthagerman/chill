import SwiftUI

/// Dedicated signup screen for new users
/// Added in: 005-split-login-and
struct AuthSignupView: View {
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
                    consentToggle
                    submitButton
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
            Text("Create Account")
                .font(.largeTitle.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            Text("Join Chill to start saving videos")
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
                .textContentType(.newPassword)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .focused($focusedField, equals: .password)
                .submitLabel(.next)
                .onSubmit { focusedField = .confirmPassword }
                .accessibilityIdentifier("auth_password")
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            
            SecureField("Confirm password", text: $viewModel.confirmPassword)
                .textContentType(.newPassword)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .focused($focusedField, equals: .confirmPassword)
                .submitLabel(.done)
                .onSubmit { 
                    focusedField = nil
                }
                .accessibilityIdentifier("auth_confirm_password")
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
        }
    }
    
    private var consentToggle: some View {
        Toggle(isOn: consentBinding) {
            Text("I agree to the Terms and Privacy Policy")
                .font(.footnote)
        }
        .toggleStyle(.switch)
        .accessibilityIdentifier("auth_consent")
    }
    
    private var consentBinding: Binding<Bool> {
        Binding(
            get: { viewModel.navigationState.consentAccepted },
            set: { viewModel.updateConsent($0) }
        )
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
                    Text("Create Account")
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
        .accessibilityLabel("Create Account")
    }
}
