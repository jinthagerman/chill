# Contract: Password Change

**Feature**: `006-add-a-profile`  
**Version**: 1.0  
**Date**: 2025-10-07

## Purpose

This contract defines the behavior and security requirements for the password change functionality. It ensures that password changes are secure, validated, and provide appropriate feedback.

---

## Password Change Contract

### Method Definition

```swift
// Extension on AuthService or dedicated PasswordChangeService
func changePassword(
    currentPassword: String,
    newPassword: String
) async throws -> Void
```

### Security Requirements

**Contract**: System MUST verify current password before allowing change

**Pre-conditions**:
1. User MUST be authenticated (valid session)
2. Current password MUST be correct
3. New password MUST meet security requirements
4. New password MUST be different from current password

**Validation Flow**:
```
1. Validate input (not empty, meets length/complexity)
2. Reauthenticate user with current password
3. If reauthentication succeeds, proceed
4. If reauthentication fails, throw .currentPasswordIncorrect
5. Update password via Supabase auth.updateUser()
6. Session remains valid (no re-login needed)
```

**Contract Tests**:
```swift
func testPasswordChangeRequiresCurrentPassword() async {
    // Given: Valid new password but wrong current password
    mockAuth.reauthError = AuthClientError(
        status: 401,
        code: "invalid_credentials",
        message: "Wrong password"
    )
    
    // When/Then: Change fails with correct error
    await assertThrowsError(
        try await service.changePassword(
            currentPassword: "wrong",
            newPassword: "NewSecure123!"
        )
    ) { error in
        XCTAssertEqual(error as? ProfileError, .currentPasswordIncorrect)
    }
}

func testPasswordChangeEnforcesMinimumLength() async {
    // Given: New password too short
    let request = PasswordChangeRequest(
        currentPassword: "current",
        newPassword: "short",
        confirmPassword: "short"
    )
    
    // Then: Validation fails
    XCTAssertFalse(request.isValid)
    XCTAssertEqual(
        request.validationError,
        "Password must be at least 8 characters"
    )
}

func testPasswordChangeRejectsIdenticalPassword() async {
    // Given: New password same as current
    let request = PasswordChangeRequest(
        currentPassword: "Password123!",
        newPassword: "Password123!",
        confirmPassword: "Password123!"
    )
    
    // Then: Validation fails
    XCTAssertFalse(request.isValid)
    XCTAssertEqual(request.validationError, "New password must be different")
}

func testPasswordChangeSucceedsWithValidCredentials() async throws {
    // Given: Valid current password and new password
    mockAuth.reauthSuccess = true
    mockAuth.updatePasswordSuccess = true
    
    // When: Changing password
    try await service.changePassword(
        currentPassword: "OldPassword123!",
        newPassword: "NewPassword123!"
    )
    
    // Then: No error thrown, password updated
    XCTAssertTrue(mockAuth.didUpdatePassword)
    XCTAssertNotNil(mockAuth.currentSession) // Session still valid
}

func testPasswordChangeRequiresConfirmation() async {
    // Given: Passwords don't match
    let request = PasswordChangeRequest(
        currentPassword: "current",
        newPassword: "newpass123",
        confirmPassword: "different123"
    )
    
    // Then: Validation fails
    XCTAssertFalse(request.isValid)
    XCTAssertEqual(request.validationError, "Passwords don't match")
}
```

---

## Password Requirements

**Contract**: New password MUST meet security requirements

**Requirements**:
1. Minimum 8 characters
2. Must be different from current password
3. Must match confirmation field
4. Cannot be empty

**Future Enhancements** (out of current scope):
- Complexity requirements (uppercase, lowercase, numbers, symbols)
- Password strength meter
- Common password blacklist
- Maximum length validation

---

## User Feedback Contract

**Contract**: System MUST provide clear feedback for password change outcome

**Success Case**:
- Dismiss password change modal
- Show success banner: "Password updated successfully"
- Session remains active (no re-login required)

**Failure Cases**:

| Error | Message | Stay on Modal |
|-------|---------|---------------|
| Current password incorrect | "Current password is incorrect." | Yes |
| Passwords don't match | "Passwords don't match" | Yes |
| Password too short | "Password must be at least 8 characters" | Yes |
| Same as current | "New password must be different" | Yes |
| Network error | "Couldn't update password. Check your connection." | Yes |
| Unknown error | "Something went wrong. Please try again." | Yes |

**Contract Tests**:
```swift
func testPasswordChangeDisplaysSuccessMessage() async throws {
    // Given: Valid password change
    mockAuth.reauthSuccess = true
    mockAuth.updatePasswordSuccess = true
    
    viewModel.currentPassword = "Old123!"
    viewModel.newPassword = "New123!"
    viewModel.confirmPassword = "New123!"
    
    // When: Submitting change
    await viewModel.submitPasswordChange()
    
    // Then: Success feedback shown
    XCTAssertEqual(viewModel.successMessage, "Password updated successfully")
    XCTAssertTrue(viewModel.shouldDismissModal)
}

func testPasswordChangeDisplaysErrorForWrongCurrentPassword() async {
    // Given: Wrong current password
    mockAuth.reauthError = AuthClientError(
        status: 401,
        code: "invalid_credentials",
        message: "Wrong"
    )
    
    viewModel.currentPassword = "wrong"
    viewModel.newPassword = "New123!"
    viewModel.confirmPassword = "New123!"
    
    // When: Submitting change
    await viewModel.submitPasswordChange()
    
    // Then: Error shown, modal stays open
    XCTAssertEqual(viewModel.errorMessage, "Current password is incorrect.")
    XCTAssertFalse(viewModel.shouldDismissModal)
}
```

---

## Security Contract

**Contract**: Password change MUST NOT leak information

**Requirements**:
1. Current password MUST NOT be logged
2. New password MUST NOT be logged
3. Error messages MUST NOT reveal whether user exists
4. Failed attempts MUST be rate-limited (via Supabase)

**Contract Tests**:
```swift
func testPasswordChangeDoesNotLogPasswords() async {
    // Mock analytics/logging
    let logger = MockLogger()
    
    // When: Password change (success or failure)
    try? await service.changePassword(
        currentPassword: "secret1",
        newPassword: "secret2"
    )
    
    // Then: Passwords not in logs
    XCTAssertFalse(logger.logs.contains("secret1"))
    XCTAssertFalse(logger.logs.contains("secret2"))
}
```

---

## Summary

**Service Responsibility**: Load and persist video preferences, handle password changes securely

**Storage**: Supabase user_metadata for preferences

**Security**: Current password verification required, passwords never logged

**Test Coverage**:
- 8+ contract tests for settings operations
- 6+ tests for password change validation
- Security and privacy verification
- Error feedback validation
