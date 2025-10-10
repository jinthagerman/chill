import SwiftUI

/// View for video settings section
/// Added in: 006-add-a-profile
struct VideoPreferencesView: View {
    @Binding var preferences: VideoPreferences
    let onSave: (VideoPreferences) async -> Void
    
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Video Quality row
            HStack {
                Text("Video Quality")
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Picker("", selection: $preferences.quality) {
                    ForEach(VideoQuality.allCases, id: \.self) { quality in
                        Text(quality.displayName)
                            .tag(quality)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("video_quality_setting")
                .onChange(of: preferences.quality) { _, _ in
                    savePreferences()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
                .padding(.leading)
            
            // Autoplay toggle row
            HStack {
                Text("Autoplay")
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Toggle("", isOn: $preferences.autoplay)
                    .labelsHidden()
                    .accessibilityIdentifier("autoplay_toggle")
                    .onChange(of: preferences.autoplay) { _, _ in
                        savePreferences()
                    }
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
                .padding(.leading)
        }
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
