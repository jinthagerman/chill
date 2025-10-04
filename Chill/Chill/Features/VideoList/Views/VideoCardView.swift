import SwiftUI

/// Individual video card component displaying thumbnail, metadata, and duration
struct VideoCardView: View {
    let card: VideoCard
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background thumbnail
            if let thumbnailURL = card.thumbnailURL {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case .empty:
                        placeholderThumbnail
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    case .failure:
                        placeholderThumbnail
                    @unknown default:
                        placeholderThumbnail
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipped()
            } else {
                placeholderThumbnail
            }
            
            // Bottom gradient overlay for better text readability
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                startPoint: .center,
                endPoint: .bottom
            )
            
            // Text overlay with blurred background at bottom
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(card.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                    
                    // Creator and platform
                    Text("\(card.creatorDisplayName) - \(card.platformDisplayName)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Duration pill
                Text(card.durationLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(6)
            }
            .padding(Spacing.stackSmall)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(16)
        .clipped()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(card.accessibilityLabel)
    }
    
    private var placeholderThumbnail: some View {
        Image(VideoListConfig.placeholderImageName)
            .resizable()
            .aspectRatio(16/9, contentMode: .fill)
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(Color.gray.opacity(0.3))
            .clipped()
            .cornerRadius(12)
    }
}

#Preview("Video Card") {
    VideoCardView(
        card: VideoCard(
            id: UUID(),
            title: "The Future of AI and Machine Learning",
            creatorDisplayName: "TechTalks",
            platformDisplayName: "YouTube",
            durationSeconds: 765,
            thumbnailURL: URL(string: "https://www.techsmith.com/wp-content/uploads/2021/02/TSC-thumbnail-example-1024x576.png"),
            updatedAt: Date()
        )
    )
    .padding()
}

#Preview("Video Card - No Thumbnail") {
    VideoCardView(
        card: VideoCard(
            id: UUID(),
            title: "Understanding SwiftUI Animations",
            creatorDisplayName: "Swift Developer",
            platformDisplayName: "Vimeo",
            durationSeconds: 420,
            thumbnailURL: nil,
            updatedAt: Date()
        )
    )
    .padding()
}
