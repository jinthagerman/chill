//
//  MetadataSection.swift
//  Chill
//
//  Created by Chill Team on 10/4/25.
//  Feature: 004-implement-add-video
//  Task: T049
//

import SwiftUI

/// Metadata rows displaying Title, Source, and Length
struct MetadataSection: View {
    
    let metadata: VideoMetadata
    
    var body: some View {
        VStack(spacing: 0) {
            // Title Row
            MetadataRow(
                label: "Title",
                value: metadata.title,
                maxLines: 2
            )
            
            Divider()
                .padding(.leading, 60)
            
            // Source Row
            MetadataRow(
                label: "Source",
                value: metadata.platform.displayName,
                maxLines: 1
            )
            
            Divider()
                .padding(.leading, 60)
            
            // Length Row
            MetadataRow(
                label: "Length",
                value: formatDuration(metadata.duration ?? 0),
                maxLines: 1
            )
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

/// Individual metadata row with label and value
struct MetadataRow: View {
    
    let label: String
    let value: String
    let maxLines: Int
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(maxLines)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }
}

// MARK: - Preview

#Preview {
    MetadataSection(
        metadata: VideoMetadata(
            title: "The Ultimate Guide to Productivity",
            videoDescription: nil,
            thumbnailURL: "https://via.placeholder.com/640x360",
            creator: "Productivity Pro",
            platform: .twitter,
            duration: 930,
            publishedDate: nil,
            videoURL: "https://example.com/video.mp4",
            size: nil
        )
    )
    .padding()
}
