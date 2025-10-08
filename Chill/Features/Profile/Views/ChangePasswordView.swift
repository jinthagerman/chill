import SwiftUI

/// Modal view for password change flow
/// Added in: 006-add-a-profile
struct ChangePasswordView: View {
    @ObservedObject var viewModel: ChangePasswordViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: PasswordField?
    
    enum PasswordField {
        case current, new, confirm
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField("Current Password", text: $viewModel.currentPassword)
                        .textContentType(.password)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .current)
                        .accessibilityIdentifier("current_password")
                        .onSubmit {
                            focusedField = .new
                        }
                } header: {
                    Text("Verify Identity")
                }
                
                Section {
                    SecureField("New Password", text: $viewModel.newPassword)
                        .textContentType(.newPassword)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .new)
                        .accessibilityIdentifier("new_password")
                        .onSubmit {
                            focusedField = .confirm
                        }
                    
                    SecureField("Confirm New Password", text: $viewModel.confirmPassword)
                        .textContentType(.newPassword)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .confirm)
                        .accessibilityIdentifier("confirm_password")
                        .onSubmit {
                            if viewModel.isValid {
                                submitPasswordChange()
                            }
                        }
                } header: {
                    Text("New Password")
                } footer: {
                    Text("Password must be at least 8 characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Success message
                if let successMessage = viewModel.successMessage {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(successMessage)
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Submit button
                Section {
                    Button(action: submitPasswordChange) {
                        HStack {
                            Spacer()
                            if viewModel.isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Update Password")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSubmitting)
                    .accessibilityIdentifier("submit_password_change")
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: viewModel.shouldDismissModal) { _, shouldDismiss in
                if shouldDismiss {
                    // Delay to show success message briefly
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Focus on first field when view appears
                focusedField = .current
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func submitPasswordChange() {
        Task {
            await viewModel.submitPasswordChange()
        }
    }
}

// MARK: - Preview

#Preview {
    // Cannot create preview without real auth service
    // Use simulator/device for testing
    Text("ChangePasswordView Preview")
        .font(.headline)
        .foregroundColor(.secondary)
}
