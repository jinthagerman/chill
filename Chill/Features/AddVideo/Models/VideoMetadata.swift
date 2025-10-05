//
//  VideoMetadata.swift
//  Chill
//
//  Created by Chill Team on 10/4/25.
//  Feature: 004-implement-add-video
//  Task: T017
//

import Foundation
import LoadifyEngine

/// Extracted information from video URL via LoadifyEngine
struct VideoMetadata: Codable {
    /// Video title
    let title: String
    
    /// Video description/summary (optional)
    /// Note: Can't use 'description' as it conflicts with NSObject.description when stored in SwiftData
    let videoDescription: String?
    
    /// URL to video thumbnail image
    let thumbnailURL: String
    
    /// Video creator/channel name
    let creator: String
    
    /// Source platform (facebook or twitter)
    let platform: VideoPlatform
    
    /// Video duration in seconds (optional)
    let duration: Int?
    
    /// Original publication date (optional)
    let publishedDate: Date?
    
    /// Direct video URL (from LoadifyEngine)
    let videoURL: String
    
    /// Video file size in bytes (optional)
    let size: Double?
    
    /// Creates VideoMetadata from LoadifyEngine response
    static func from(loadifyResponse: LoadifyResponse, originalURL: String) -> VideoMetadata {
        // Map LoadifyEngine platform to our VideoPlatform
        let platform: VideoPlatform = {
            switch loadifyResponse.platform {
            case .facebook:
                return .facebook
            case .twitter:
                return .twitter
            default:
                // TikTok, Instagram not supported
                fatalError("Unsupported platform: \(loadifyResponse.platform)")
            }
        }()
        
        // Use user name as creator, fallback to "Unknown creator"
        let creator = loadifyResponse.user?.name ?? "Unknown creator"
        
        // Use video URL or user name as title (LoadifyEngine doesn't provide explicit title)
        let title = loadifyResponse.user?.name ?? "Video"
        
        return VideoMetadata(
            title: title,
            videoDescription: nil, // LoadifyEngine doesn't provide description
            thumbnailURL: loadifyResponse.video.thumbnail,
            creator: creator,
            platform: platform,
            duration: nil, // LoadifyEngine doesn't provide duration
            publishedDate: nil, // LoadifyEngine doesn't provide published date
            videoURL: loadifyResponse.video.url,
            size: loadifyResponse.video.size
        )
    }
}
