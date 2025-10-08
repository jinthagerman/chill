import SwiftUI

/// View component to display account information
/// Added in: 006-add-a-profile
struct ProfileHeaderView: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Display name (large, bold)
            Text(profile.displayName)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .accessibilityLabel("Display name: \(profile.displayName)")
            
            // Email address
            Text(profile.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .accessibilityLabel("Email: \(profile.email)")
            
            // Verification status badge
            HStack(spacing: 8) {
                Image(systemName: profile.isVerified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(profile.isVerified ? .green : .orange)
                    .font(.caption)
                
                Text(profile.isVerified ? "Verified" : "Unverified")
                    .font(.caption)
                    .foregroundColor(profile.isVerified ? .green : .orange)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(profile.isVerified ? "Account verified" : "Account not verified")
            
            Divider()
                .padding(.vertical, 4)
            
            // Account stats grid
            VStack(alignment: .leading, spacing: 12) {
                // Account creation date
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    
                    Text("Joined \(formatAccountCreationDate(profile.accountCreatedAt))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .accessibilityIdentifier("account_created")
                .accessibilityLabel("Joined \(formatAccountCreationDate(profile.accountCreatedAt))")
                
                // Last login
                if let lastLogin = profile.lastLoginAt {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                        
                        Text("Last active \(formatRelativeTime(lastLogin))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityIdentifier("last_login")
                    .accessibilityLabel("Last active \(formatRelativeTime(lastLogin))")
                }
                
                // Saved videos count
                HStack {
                    Image(systemName: "video.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    
                    Text("\(profile.savedVideosCount) videos saved")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .accessibilityIdentifier("saved_videos_count")
                .accessibilityLabel("\(profile.savedVideosCount) videos saved")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Functions
    
    private func formatAccountCreationDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
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
