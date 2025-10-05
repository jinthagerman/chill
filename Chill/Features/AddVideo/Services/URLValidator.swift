//
//  URLValidator.swift
//  Chill
//
//  Created by Chill Team on 10/4/25.
//  Feature: 004-implement-add-video
//  Tasks: T020, T021, T022, T023
//

import Foundation

/// Validates video URLs for supported platforms (Facebook and Twitter only)
class URLValidator {
    
    // MARK: - Regex Patterns (from research.md)
    
    /// Facebook URL patterns: standard, watch, short (fb.watch), mobile
    private let facebookPattern = #"^(https?://)?(www\.|m\.)?(facebook\.com/([\w.]+/videos/|watch/\?v=)|fb\.watch/)[\w-]+"#
    
    /// Twitter URL patterns: twitter.com, x.com, mobile, t.co shortened
    private let twitterPattern = #"^(https?://)?(www\.|mobile\.)?(twitter\.com|x\.com)/[\w]+/status/\d+|^(https?://)?t\.co/[\w]+"#
    
    /// Unsupported platforms (for rejection messaging)
    private let youtubePattern = #"(youtube\.com|youtu\.be)"#
    private let tiktokPattern = #"tiktok\.com"#
    private let instagramPattern = #"instagram\.com"#
    
    // MARK: - Public API
    
    /// Validates a URL string and returns validation result
    /// - Parameter url: The URL string to validate
    /// - Returns: URLValidationResult with validation status, platform, and normalized URL
    func validate(_ url: String) -> URLValidationResult {
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if empty
        guard !trimmedURL.isEmpty else {
            return .failure(message: "Please enter a valid video URL")
        }
        
        // Check for basic URL format
        guard trimmedURL.contains(".") && (trimmedURL.hasPrefix("http") || !trimmedURL.hasPrefix("javascript:")) else {
            return .failure(message: "Please enter a valid video URL")
        }
        
        // Check for unsupported platforms first (clearer error messages)
        if trimmedURL.range(of: youtubePattern, options: .regularExpression) != nil {
            return .failure(message: "Only Facebook and Twitter videos are supported")
        }
        if trimmedURL.range(of: tiktokPattern, options: .regularExpression) != nil {
            return .failure(message: "Only Facebook and Twitter videos are supported")
        }
        if trimmedURL.range(of: instagramPattern, options: .regularExpression) != nil {
            return .failure(message: "Only Facebook and Twitter videos are supported")
        }
        
        // Check Facebook patterns
        if trimmedURL.range(of: facebookPattern, options: .regularExpression) != nil {
            let normalized = normalizeURL(trimmedURL)
            return .success(platform: .facebook, normalizedURL: normalized)
        }
        
        // Check Twitter patterns
        if trimmedURL.range(of: twitterPattern, options: .regularExpression) != nil {
            let normalized = normalizeURL(trimmedURL)
            return .success(platform: .twitter, normalizedURL: normalized)
        }
        
        // No pattern matched
        return .failure(message: "Please enter a valid video URL")
    }
    
    // MARK: - URL Normalization (Task T022)
    
    /// Normalizes URL for consistent duplicate detection
    /// - Converts to lowercase
    /// - Removes tracking parameters (?utm_*, ?fbclid=, etc.)
    /// - Strips www., m., mobile. prefixes
    /// - Expands shortened URLs to canonical form
    /// - Removes trailing slashes
    func normalizeURL(_ url: String) -> String {
        var normalized = url.lowercased()
        
        // Remove protocol
        normalized = normalized
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        
        // Remove prefixes
        normalized = normalized
            .replacingOccurrences(of: "www.", with: "")
            .replacingOccurrences(of: "m.", with: "")
            .replacingOccurrences(of: "mobile.", with: "")
        
        // Expand shortened URLs to canonical form
        normalized = normalized
            .replacingOccurrences(of: "youtu.be/", with: "youtube.com/watch?v=")
            .replacingOccurrences(of: "fb.watch/", with: "facebook.com/watch/?v=")
        
        // Remove query parameters except essential ones (like v= for video ID)
        if let questionIndex = normalized.firstIndex(of: "?") {
            let baseURL = String(normalized[..<questionIndex])
            let queryString = String(normalized[normalized.index(after: questionIndex)...])
            
            // Keep only essential parameters
            let params = queryString.split(separator: "&")
            let essentialParams = params.filter { param in
                param.hasPrefix("v=") // Keep video ID parameter
            }
            
            if essentialParams.isEmpty {
                normalized = baseURL
            } else {
                normalized = baseURL + "?" + essentialParams.joined(separator: "&")
            }
        }
        
        // Remove trailing slash
        normalized = normalized.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        return normalized
    }
}
