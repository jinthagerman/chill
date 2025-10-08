import SwiftUI

/// View for security settings section
/// Added in: 006-add-a-profile
struct AccountSecurityView: View {
    let onChangePassword: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("Account Security")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Change Password button
            Button(action: onChangePassword) {
                HStack {
                    Image(systemName: "lock.rotation")
                        .foregroundColor(.accentColor)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Change Password")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Text("Update your account password")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
            .accessibilityIdentifier("change_password")
            .accessibilityLabel("Change Password")
            .accessibilityHint("Double tap to change your password")
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    AccountSecurityView(
        onChangePassword: {
            print("Change password tapped")
        }
    )
    .padding()
}
