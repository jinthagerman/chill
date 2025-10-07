//
//  AddVideoEvent.swift
//  Chill
//
//  Created by Chill Team on 10/4/25.
//  Feature: 004-implement-add-video
//  Task: T019
//

import Foundation

/// Analytics event for add video flow tracking
struct AddVideoEvent: Codable {
    let eventType: EventType
    let timestamp: Date
    let outcome: EventOutcome?
    let errorType: ErrorType?
    let platform: String?
    let durationMs: Int?
    
    init(
        eventType: EventType,
        outcome: EventOutcome? = nil,
        errorType: ErrorType? = nil,
        platform: String? = nil,
        durationMs: Int? = nil
    ) {
        self.eventType = eventType
        self.timestamp = Date()
        self.outcome = outcome
        self.errorType = errorType
        self.platform = platform
        self.durationMs = durationMs
    }
    
    // MARK: - Event Types
    
    enum EventType: String, Codable {
        case modalOpened = "add_video_modal_opened"
        case urlSubmitted = "add_video_url_submitted"
        case validationFailed = "add_video_validation_failed"
        case metadataFetched = "add_video_metadata_fetched"
        case confirmationScreenOpened = "add_video_confirmation_opened"
        case videoSaved = "add_video_saved"
        case flowCancelled = "add_video_cancelled"
        case errorOccurred = "add_video_error"
    }
    
    // MARK: - Event Outcomes
    
    enum EventOutcome: String, Codable {
        case success
        case failure
        case cancelled
    }
    
    // MARK: - Error Types
    
    enum ErrorType: String, Codable {
        case invalidFormat = "invalid_format"
        case unsupportedPlatform = "unsupported_platform"
        case networkError = "network_error"
        case timeout = "timeout"
        case extractionFailed = "extraction_failed"
        case duplicateVideo = "duplicate_video"
        case submissionFailed = "submission_failed"
        case unknownError = "unknown_error"
    }
}

// MARK: - Analytics Service Integration

/// Protocol for analytics service integration
protocol AnalyticsServiceProtocol {
    func track(event: AddVideoEvent)
}

/// Analytics service for tracking add video events
class AddVideoAnalyticsService: AnalyticsServiceProtocol {
    
    // MARK: - Singleton
    
    static let shared = AddVideoAnalyticsService()
    
    private init() {}
    
    // MARK: - Event Tracking
    
    func track(event: AddVideoEvent) {
        // Privacy requirement: Never log URL content
        let sanitizedEvent = sanitize(event)
        
        #if DEBUG
        print("📊 Analytics: \(sanitizedEvent.eventType.rawValue)")
        if let outcome = sanitizedEvent.outcome {
            print("   Outcome: \(outcome.rawValue)")
        }
        if let errorType = sanitizedEvent.errorType {
            print("   Error: \(errorType.rawValue)")
        }
        if let platform = sanitizedEvent.platform {
            print("   Platform: \(platform)")
        }
        if let duration = sanitizedEvent.durationMs {
            print("   Duration: \(duration)ms")
        }
        #endif
        
        // TODO: Integrate with real analytics backend (e.g., Mixpanel, Firebase, PostHog)
        // Example:
        // Analytics.track(
        //     name: sanitizedEvent.eventType.rawValue,
        //     properties: [
        //         "outcome": sanitizedEvent.outcome?.rawValue,
        //         "error_type": sanitizedEvent.errorType?.rawValue,
        //         "platform": sanitizedEvent.platform,
        //         "duration_ms": sanitizedEvent.durationMs
        //     ]
        // )
    }
    
    // MARK: - Privacy Sanitization
    
    private func sanitize(_ event: AddVideoEvent) -> AddVideoEvent {
        // Ensure no URL content or PII is logged
        // Currently all fields are safe - no URL strings captured
        return event
    }
    
    // MARK: - Convenience Methods
    
    func trackModalOpened() {
        track(event: AddVideoEvent(eventType: .modalOpened))
    }
    
    func trackURLSubmitted(platform: String) {
        track(event: AddVideoEvent(
            eventType: .urlSubmitted,
            platform: platform
        ))
    }
    
    func trackValidationFailed(errorType: AddVideoEvent.ErrorType) {
        track(event: AddVideoEvent(
            eventType: .validationFailed,
            outcome: .failure,
            errorType: errorType
        ))
    }
    
    func trackMetadataFetched(platform: String, durationMs: Int) {
        track(event: AddVideoEvent(
            eventType: .metadataFetched,
            outcome: .success,
            platform: platform,
            durationMs: durationMs
        ))
    }
    
    func trackConfirmationOpened() {
        track(event: AddVideoEvent(eventType: .confirmationScreenOpened))
    }
    
    func trackVideoSaved(platform: String) {
        track(event: AddVideoEvent(
            eventType: .videoSaved,
            outcome: .success,
            platform: platform
        ))
    }
    
    func trackFlowCancelled(stage: String) {
        track(event: AddVideoEvent(
            eventType: .flowCancelled,
            outcome: .cancelled
        ))
    }
    
    func trackError(errorType: AddVideoEvent.ErrorType, platform: String? = nil) {
        track(event: AddVideoEvent(
            eventType: .errorOccurred,
            outcome: .failure,
            errorType: errorType,
            platform: platform
        ))
    }
}
