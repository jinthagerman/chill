import Foundation
import Combine

/// ViewModel for ChangePasswordView - handles password change validation and submission
/// Added in: 006-add-a-profile
@MainActor
final class ChangePasswordViewModel: ObservableObject {
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var shouldDismissModal: Bool = false
    @Published var isSubmitting: Bool = false
    
    private let authService: AuthServiceType
    private let analytics: ((ProfileEventPayload) -> Void)?
    
    init(authService: AuthServiceType, analytics: ((ProfileEventPayload) -> Void)? = nil) {
        self.authService = authService
        self.analytics = analytics
    }
    
    /// Validation computed property
    var isValid: Bool {
        let request = PasswordChangeRequest(
            currentPassword: currentPassword,
            newPassword: newPassword,
            confirmPassword: confirmPassword
        )
        return request.isValid
    }
    
    /// Get validation error message
    var validationError: String? {
        let request = PasswordChangeRequest(
            currentPassword: currentPassword,
            newPassword: newPassword,
            confirmPassword: confirmPassword
        )
        return request.validationError
    }
    
    /// Submit password change
    func submitPasswordChange() async {
        let startTime = Date()
        
        // Clear previous messages
        errorMessage = nil
        successMessage = nil
        
        // Validate inputs
        guard isValid else {
            errorMessage = validationError
            return
        }
        
        // Set submitting state
        isSubmitting = true
        
        do {
            // Call auth service to change password
            try await authService.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            
            // Success - show message and prepare to dismiss
            successMessage = "Password updated successfully"
            shouldDismissModal = true
            
            // Track success
            logAnalyticsEvent(result: .success, startTime: startTime)
            
            // Clear fields
            clearFields()
        } catch let error as ProfileError {
            // Handle profile errors
            errorMessage = error.userMessage
            shouldDismissModal = false
            
            // Track failure
            logAnalyticsEvent(
                result: .failure,
                errorCode: String(describing: error),
                startTime: startTime
            )
        } catch {
            // Handle unexpected errors
            errorMessage = "Something went wrong. Please try again."
            shouldDismissModal = false
            
            // Track failure
            logAnalyticsEvent(
                result: .failure,
                errorCode: "unknown",
                startTime: startTime
            )
        }
        
        isSubmitting = false
    }
    
    // MARK: - Analytics
    
    private func logAnalyticsEvent(
        result: EventResult,
        errorCode: String? = nil,
        startTime: Date
    ) {
        let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)
        
        let payload = ProfileEventPayload(
            eventType: .passwordChanged,
            result: result,
            settingKey: nil,
            settingValue: nil,
            errorCode: errorCode,
            latencyMs: latencyMs
        )
        
        analytics?(payload)
    }
    
    /// Clear all password fields
    func clearFields() {
        currentPassword = ""
        newPassword = ""
        confirmPassword = ""
    }
}
