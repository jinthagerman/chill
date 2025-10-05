//
//  VideoPreviewCard.swift
//  Chill
//
//  Created by Chill Team on 10/4/25.
//  Feature: 004-implement-add-video
//  Tasks: T047, T048
//

import SwiftUI

/// Large video preview card with thumbnail and overlays
struct VideoPreviewCard: View {
    
    let metadata: VideoMetadata
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Thumbnail Image (Task T047)
                AsyncImage(url: URL(string: metadata.thumbnailURL)) { phase in
                    switch phase {
                    case .empty:
                        // Loading state
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        // Error state - placeholder
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16) // 16:9 aspect ratio
                .clipped()
                
                // Overlays (Task T048)
                
                // Gradient overlay for text readability
                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                
                // Play Button Overlay (center)
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                
                VStack(alignment: .leading) {
                    // Platform Badge (top-left)
                    Text(metadata.platform.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                        .padding(12)
                    
                    Spacer()
                    
                    // Video Title and Duration (bottom-left)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(metadata.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        if let duration = metadata.duration {
                            Text(formatDuration(duration))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(6)
                        }
                    }
                    .padding(16)
                }
                .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Video preview, \(metadata.title), \(formatDuration(metadata.duration ?? 0)), \(metadata.platform.displayName)")
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Preview

#Preview {
    VideoPreviewCard(
        metadata: VideoMetadata(
            title: "The Ultimate Guide to Productivity",
            videoDescription: nil,
            thumbnailURL: "https://via.placeholder.com/640x360",
            creator: "Productivity Pro",
            platform: .twitter,
            duration: 930, // 15:30
            publishedDate: nil,
            videoURL: "https://example.com/video.mp4",
            size: nil
        )
    )
    .padding()
}
