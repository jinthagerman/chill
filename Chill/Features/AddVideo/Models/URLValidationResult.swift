//
//  URLValidationResult.swift
//  Chill
//
//  Created by Chill Team on 10/4/25.
//  Feature: 004-implement-add-video
//  Task: T018
//

import Foundation

/// Result of URL format and platform validation (ephemeral, not persisted)
struct URLValidationResult {
    /// True if URL matches supported platform pattern
    let isValid: Bool
    
    /// Detected platform (facebook or twitter)
    let platform: VideoPlatform?
    
    /// User-facing error message if invalid
    let errorMessage: String?
    
    /// Normalized URL for duplicate detection
    let normalizedURL: String?
    
    /// Creates a successful validation result
    static func success(platform: VideoPlatform, normalizedURL: String) -> URLValidationResult {
        return URLValidationResult(
            isValid: true,
            platform: platform,
            errorMessage: nil,
            normalizedURL: normalizedURL
        )
    }
    
    /// Creates a failed validation result
    static func failure(message: String) -> URLValidationResult {
        return URLValidationResult(
            isValid: false,
            platform: nil,
            errorMessage: message,
            normalizedURL: nil
        )
    }
}
