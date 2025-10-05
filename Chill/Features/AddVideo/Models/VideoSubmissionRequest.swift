//
//  VideoSubmissionRequest.swift
//  Chill
//
//  Created by Chill Team on 10/4/25.
//  Feature: 004-implement-add-video
//  Task: T016
//

import Foundation
import SwiftData

/// SwiftData model for offline video submission queue
@Model
final class VideoSubmissionRequest {
    
    // MARK: - Properties
    
    /// Unique identifier
    @Attribute(.unique) var id: UUID
    
    /// Original video URL (user input)
    var originalURL: String
    
    /// Normalized URL for duplicate detection
    @Attribute(.unique) var normalizedURL: String
    
    /// User-provided description (optional)
    /// Note: Can't use 'description' as it conflicts with NSObject.description
    var userProvidedDescription: String?
    
    /// Current submission status
    var status: SubmissionStatus
    
    /// Number of retry attempts
    var retryCount: Int
    
    /// Last error message (if failed)
    var lastErrorMessage: String?
    
    /// Extracted metadata (after successful fetch)
    var metadata: VideoMetadata?
    
    /// User ID who created this submission
    var userId: UUID
    
    /// Creation timestamp
    var createdAt: Date
    
    /// Last update timestamp
    var updatedAt: Date
    
    /// Next retry timestamp (for exponential backoff)
    var nextRetryAt: Date?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        originalURL: String,
        normalizedURL: String,
        userProvidedDescription: String? = nil,
        userId: UUID,
        status: SubmissionStatus = .pending
    ) {
        self.id = id
        self.originalURL = originalURL
        self.normalizedURL = normalizedURL
        self.userProvidedDescription = userProvidedDescription
        self.userId = userId
        self.status = status
        self.retryCount = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Helpers
    
    /// Update status and timestamp
    func updateStatus(_ newStatus: SubmissionStatus) {
        self.status = newStatus
        self.updatedAt = Date()
    }
    
    /// Increment retry count and calculate next retry time
    func incrementRetry() {
        retryCount += 1
        updatedAt = Date()
        
        // Exponential backoff: 30s, 2m, 5m
        let delays: [TimeInterval] = [30, 120, 300]
        let delayIndex = min(retryCount - 1, delays.count - 1)
        nextRetryAt = Date().addingTimeInterval(delays[delayIndex])
    }
    
    /// Check if ready for retry
    var isReadyForRetry: Bool {
        guard status == .failed else { return false }
        guard retryCount < 3 else { return false }
        
        if let nextRetry = nextRetryAt {
            return Date() >= nextRetry
        }
        
        return true
    }
}

// MARK: - Submission Status

extension VideoSubmissionRequest {
    /// Status of the submission request
    enum SubmissionStatus: String, Codable {
        /// Waiting to be processed
        case pending
        
        /// Currently being processed
        case processing
        
        /// Successfully submitted to backend
        case completed
        
        /// Failed (will retry if retryCount < 3)
        case failed
    }
}

// MARK: - SwiftData Configuration

extension VideoSubmissionRequest {
    /// SwiftData schema for indexing
    static var schema: Schema {
        Schema([VideoSubmissionRequest.self])
    }
}
