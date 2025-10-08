import SwiftUI

/// View for video settings section
/// Added in: 006-add-a-profile
struct VideoPreferencesView: View {
    @Binding var preferences: VideoPreferences
    let onSave: (VideoPreferences) async -> Void
    
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            Text("Video Preferences")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Video quality picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Video Quality")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Video Quality", selection: $preferences.quality) {
                    ForEach(VideoQuality.allCases, id: \.self) { quality in
                        Text(quality.displayName)
                            .tag(quality)
                            .accessibilityIdentifier("quality_\(quality.rawValue)")
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("video_quality_setting")
                .accessibilityLabel("Video quality")
                .onChange(of: preferences.quality) { _, _ in
                    savePreferences()
                }
            }
            
            Divider()
            
            // Autoplay toggle
            Toggle(isOn: $preferences.autoplay) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Autoplay")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text("Start playing videos automatically")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityIdentifier("autoplay_toggle")
            .accessibilityLabel("Autoplay")
            .accessibilityHint("Double tap to toggle autoplay on or off")
            .onChange(of: preferences.autoplay) { _, _ in
                savePreferences()
            }
            
            // Save confirmation
            if showingSaveConfirmation {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Setting saved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Functions
    
    private func savePreferences() {
        Task {
            await onSave(preferences)
            
            // Show brief confirmation
            withAnimation {
                showingSaveConfirmation = true
            }
            
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            withAnimation {
                showingSaveConfirmation = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var preferences = VideoPreferences.default
    
    VideoPreferencesView(
        preferences: $preferences,
        onSave: { prefs in
            print("Saving preferences: \(prefs)")
        }
    )
    .padding()
}
