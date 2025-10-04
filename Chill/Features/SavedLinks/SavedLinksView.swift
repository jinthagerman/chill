import SwiftUI

struct SavedLinksView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "bookmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Saved Links")
                    .font(.largeTitle.weight(.semibold))
                Text("Your authenticated space for Chill will live here soon. For now, enjoy a calm landing screen while we prepare saved links.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }

            Text("Stay tuned for upcoming releases that bring your saved moments together.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
