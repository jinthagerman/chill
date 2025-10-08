import SwiftUI

/// View for security settings section
/// Added in: 006-add-a-profile
struct AccountSecurityView: View {
    let onChangePassword: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Change password row
            Button(action: onChangePassword) {
                HStack {
                    Text("Change Password")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color(.systemBackground))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("change_password")
            .accessibilityLabel("Change Password")
        }
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
