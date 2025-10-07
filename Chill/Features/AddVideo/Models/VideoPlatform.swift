//
//  VideoPlatform.swift
//  Chill
//
//  Created by Chill Team on 10/4/25.
//  Feature: 004-implement-add-video
//

import Foundation

/// Supported video platforms for URL submission
/// Currently: Facebook and Twitter only (per clarification 2025-10-04)
enum VideoPlatform: String, Codable {
    case facebook
    case twitter
    
    var displayName: String {
        switch self {
        case .facebook:
            return "Facebook"
        case .twitter:
            return "Twitter"
        }
    }
}
