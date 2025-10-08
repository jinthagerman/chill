import SwiftUI

/// View component to display account information
/// Added in: 006-add-a-profile
struct ProfileHeaderView: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 20) {
            // Avatar (circular placeholder with person icon)
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .accessibilityLabel("Profile avatar")
            
            // Display name (large, bold, centered)
            Text(profile.displayName)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
                .accessibilityLabel("Display name: \(profile.displayName)")
            
            // Email/username with verification badge (centered)
            HStack(spacing: 6) {
                Text("@\(formatUsername(profile.email))")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                if profile.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.blue)
                        .font(.body)
                }
            }
            .accessibilityLabel(profile.isVerified ? "Username: \(formatUsername(profile.email)), verified" : "Username: \(formatUsername(profile.email))")
            
            // Joined date (centered)
            Text("Joined \(formatAccountYear(profile.accountCreatedAt))")
                .font(.body)
                .foregroundColor(.secondary)
                .accessibilityIdentifier("account_created")
                .accessibilityLabel("Joined \(formatAccountYear(profile.accountCreatedAt))")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Helper Functions
    
    private func formatUsername(_ email: String) -> String {
        // Extract username from email (part before @)
        return email.components(separatedBy: "@").first ?? email
    }
    
    private func formatAccountYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    ProfileHeaderView(
        profile: UserProfile(
            userID: UUID(),
            email: "user@example.com",
            displayName: "John Doe",
            accountCreatedAt: Date().addingTimeInterval(-86400 * 365), // 1 year ago
            isVerified: true,
            lastLoginAt: Date().addingTimeInterval(-3600), // 1 hour ago
            savedVideosCount: 42
        )
    )
    .padding()
}
