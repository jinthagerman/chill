import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel: AuthViewModel
    @State private var selectedSegment: AuthSegment
    @FocusState private var focusedField: Field?

    init(viewModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _selectedSegment = State(initialValue: AuthSegment(mode: viewModel.mode))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if showsAuthenticationSegments {
                    modePicker
                }

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
                primaryButton
                secondaryActions
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onChange(of: viewModel.mode) { newValue in
            selectedSegment = AuthSegment(mode: newValue)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title(for: viewModel.mode))
                .font(.largeTitle.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            Text(subtitle(for: viewModel.mode))
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    private var modePicker: some View {
        Picker("Authentication Mode", selection: $selectedSegment) {
            ForEach(AuthSegment.allCases) { segment in
                Text(segment.title).tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedSegment) { segment in
            switch segment {
            case .login:
                viewModel.updateMode(.login)
            case .signup:
                let consent = viewModel.mode.consentAccepted
                viewModel.updateMode(.signup(consentAccepted: consent))
            }
            focusedField = .email
        }
    }

    private var formFields: some View {
        VStack(spacing: 16) {
            emailField

            switch viewModel.mode {
            case .login:
                passwordField
            case let .signup:
                passwordField
                confirmPasswordField
                consentToggle
            case .resetRequest:
                EmptyView()
            case .resetVerify:
                otpField
                passwordField
            }
        }
    }

    private var emailField: some View {
        TextField("Email address", text: $viewModel.email)
            .textContentType(.username)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .focused($focusedField, equals: .email)
            .submitLabel(nextSubmitLabel)
            .onSubmit { focusNext(after: .email) }
            .accessibilityIdentifier("auth_email")
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
    }

    private var passwordField: some View {
        SecureField(passwordLabel, text: $viewModel.password)
            .textContentType(.password)
            .focused($focusedField, equals: .password)
            .submitLabel(passwordSubmitLabel)
            .onSubmit { focusNext(after: .password) }
            .accessibilityIdentifier("auth_password")
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
    }

    private var confirmPasswordField: some View {
        SecureField("Confirm password", text: $viewModel.confirmPassword)
            .textContentType(.newPassword)
            .focused($focusedField, equals: .confirmPassword)
            .submitLabel(.done)
            .onSubmit { focusedField = nil }
            .accessibilityIdentifier("auth_confirm_password")
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
    }

    private var otpField: some View {
        TextField("6-digit code", text: $viewModel.otpCode)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($focusedField, equals: .otp)
            .submitLabel(.next)
            .onSubmit { focusNext(after: .otp) }
            .accessibilityLabel("Verification code")
            .accessibilityIdentifier("auth_otp")
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
    }

    private var consentToggle: some View {
        Toggle(isOn: consentBinding) {
            Text("I agree to the Terms and Privacy Policy")
                .font(.footnote)
        }
        .toggleStyle(.switch)
    }

    private var primaryButton: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            Group {
                if viewModel.isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text(viewModel.ctaLabel)
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
        .disabled(viewModel.isProcessing || viewModel.canSubmit == false)
        .accessibilityIdentifier("auth_primary_cta")
        .accessibilityHint(buttonHint(for: viewModel.mode))
    }

    private var secondaryActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch viewModel.mode {
            case .login:
                Button("Forgot password?") {
                    viewModel.updateMode(.resetRequest)
                    focusedField = .email
                }
                .accessibilityIdentifier("auth_forgot_password")
            case .resetRequest, .resetVerify:
                Button("Back to Log In") {
                    selectedSegment = .login
                    viewModel.updateMode(.login)
                    focusedField = .email
                }
                .accessibilityIdentifier("auth_back_to_login")
            case .signup:
                EmptyView()
            }
        }
        .font(.callout)
        .foregroundColor(.accentColor)
    }

    private var consentBinding: Binding<Bool> {
        Binding(
            get: { viewModel.mode.consentAccepted },
            set: { newValue in
                viewModel.updateMode(.signup(consentAccepted: newValue))
            }
        )
    }

    private var showsAuthenticationSegments: Bool {
        switch viewModel.mode {
        case .login, .signup:
            return true
        case .resetRequest, .resetVerify:
            return false
        }
    }

    private var nextSubmitLabel: SubmitLabel {
        switch viewModel.mode {
        case .login, .signup:
            return .next
        case .resetRequest:
            return .done
        case .resetVerify:
            return .next
        }
    }

    private var passwordSubmitLabel: SubmitLabel {
        switch viewModel.mode {
        case .login:
            return .done
        case .signup:
            return .next
        case .resetRequest:
            return .done
        case .resetVerify:
            return .done
        }
    }

    private var passwordLabel: String {
        switch viewModel.mode {
        case .resetVerify:
            return "New password"
        default:
            return "Password"
        }
    }

    private func focusNext(after field: Field) {
        switch (field, viewModel.mode) {
        case (.email, .login):
            focusedField = .password
        case (.email, .signup):
            focusedField = .password
        case (.email, .resetRequest):
            focusedField = nil
        case (.email, .resetVerify):
            focusedField = .otp
        case (.password, .signup):
            focusedField = .confirmPassword
        case (.password, .resetVerify):
            focusedField = nil
        case (.password, .login):
            focusedField = nil
        case (.otp, _):
            focusedField = .password
        default:
            focusedField = nil
        }
    }

    private func title(for mode: AuthMode) -> String {
        switch mode {
        case .login:
            return "Welcome Back"
        case .signup:
            return "Create Your Account"
        case .resetRequest:
            return "Reset Password"
        case .resetVerify:
            return "Enter Verification Code"
        }
    }

    private func subtitle(for mode: AuthMode) -> String {
        switch mode {
        case .login:
            return "Log in to continue where you left off."
        case .signup:
            return "A few quick details to start saving links."
        case .resetRequest:
            return "We'll email you a one-time code to reset your password."
        case .resetVerify:
            return "Check your inbox for the code we just sent."
        }
    }

    private func buttonHint(for mode: AuthMode) -> String {
        switch mode {
        case .login:
            return "Attempts to sign you in with the email and password above."
        case .signup:
            return "Creates a Chill account with the details provided."
        case .resetRequest:
            return "Sends a password reset code to the email you entered."
        case .resetVerify:
            return "Verifies the code and updates your password."
        }
    }

    private enum Field {
        case email
        case password
        case confirmPassword
        case otp
    }
}

private enum AuthSegment: String, CaseIterable, Identifiable {
    case login
    case signup

    var id: Self { self }

    var title: String {
        switch self {
        case .login:
            return "Log In"
        case .signup:
            return "Sign Up"
        }
    }

    init(mode: AuthMode) {
        switch mode {
        case .signup:
            self = .signup
        default:
            self = .login
        }
    }
}

private struct BannerView: View {
    let banner: AuthBanner

    var body: some View {
        Text(banner.message)
            .font(.callout)
            .foregroundColor(foregroundColor)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .cornerRadius(12)
            .accessibilityIdentifier("auth_banner")
            .accessibilityAddTraits(.isStaticText)
    }

    private var foregroundColor: Color {
        switch banner.type {
        case .success:
            return Color(.systemGreen)
        case .error:
            return Color(.systemRed)
        case .info:
            return Color(.systemBlue)
        }
    }

    private var backgroundColor: Color {
        foregroundColor.opacity(0.12)
    }
}

private extension AuthMode {
    var consentAccepted: Bool {
        if case let .signup(consent) = self {
            return consent
        }
        return false
    }
}

