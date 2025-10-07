//
//  VideoSubmissionQueue.swift
//  Chill
//
//  Created by Chill Team on 10/4/25.
//  Feature: 004-implement-add-video
//  Tasks: T027, T028, T029, T030, T031
//

import Foundation
import SwiftData

/// Manages offline video submission queue with auto-retry
@MainActor
class VideoSubmissionQueue {
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let addVideoService: AddVideoService
    private let connectivityMonitor: ConnectivityMonitor
    
    // MARK: - State
    
    private var isProcessing = false
    
    // MARK: - Initialization (Task T027)
    
    init(
        modelContext: ModelContext,
        addVideoService: AddVideoService,
        connectivityMonitor: ConnectivityMonitor
    ) {
        self.modelContext = modelContext
        self.addVideoService = addVideoService
        self.connectivityMonitor = connectivityMonitor
        
        // Start monitoring connectivity for auto-retry
        setupConnectivityMonitoring()
    }
    
    // MARK: - Queue Management
    
    /// Creates a new submission request and queues it (Task T028)
    /// - Parameters:
    ///   - originalURL: The video URL
    ///   - normalizedURL: Normalized URL for deduplication
    ///   - userProvidedDescription: Optional description
    ///   - userId: Current user ID
    /// - Returns: The created submission request
    func createSubmission(
        originalURL: String,
        normalizedURL: String,
        userProvidedDescription: String?,
        userId: UUID
    ) throws -> VideoSubmissionRequest {
        
        let submission = VideoSubmissionRequest(
            originalURL: originalURL,
            normalizedURL: normalizedURL,
            userProvidedDescription: userProvidedDescription,
            userId: userId
        )
        
        modelContext.insert(submission)
        try modelContext.save()
        
        // Try to process immediately if online
        Task {
            await processQueue()
        }
        
        return submission
    }
    
    /// Processes pending submissions in the queue (Task T029)
    func processQueue() async {
        guard !isProcessing else { return }
        guard connectivityMonitor.isConnected else {
            print("🔄 Queue: Offline, skipping processing")
            return
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Fetch pending and ready-to-retry submissions
            // Note: Can't use enum cases directly in Predicate, so we fetch all and filter
            let descriptor = FetchDescriptor<VideoSubmissionRequest>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            
            let allSubmissions = try modelContext.fetch(descriptor)
            
            // Filter to only pending or failed submissions
            let submissions = allSubmissions.filter { submission in
                submission.status == .pending || submission.status == .failed
            }
            
            for submission in submissions {
                // Skip if not ready for retry
                if submission.status == .failed && !submission.isReadyForRetry {
                    continue
                }
                
                await processSubmission(submission)
            }
            
        } catch {
            print("❌ Queue: Error fetching submissions: \(error)")
        }
    }
    
    /// Processes a single submission (Task T029)
    private func processSubmission(_ submission: VideoSubmissionRequest) async {
        submission.updateStatus(.processing)
        
        do {
            try modelContext.save()
            
            // Extract metadata if not already fetched
            let metadata: VideoMetadata
            if let existingMetadata = submission.metadata {
                metadata = existingMetadata
            } else {
                metadata = try await addVideoService.extractMetadata(from: submission.originalURL)
                submission.metadata = metadata
                try modelContext.save()
            }
            
            // Submit to Supabase
            let videoId = try await addVideoService.submitToSupabase(
                metadata: metadata,
                userNotes: submission.userProvidedDescription,
                userId: submission.userId,
                originalURL: submission.originalURL
            )
            
            // Mark as completed
            submission.updateStatus(.completed)
            try modelContext.save()
            
            print("✅ Queue: Successfully submitted video \(videoId)")
            
            // Track analytics
            AddVideoAnalyticsService.shared.trackVideoSaved(platform: metadata.platform.displayName)
            
        } catch {
            // Handle failure
            submission.lastErrorMessage = error.localizedDescription
            submission.incrementRetry()
            
            if submission.retryCount >= 3 {
                submission.updateStatus(.failed)
                print("❌ Queue: Submission failed after 3 retries: \(submission.id)")
            } else {
                submission.updateStatus(.failed)
                print("⚠️ Queue: Submission failed, will retry (attempt \(submission.retryCount)/3)")
            }
            
            try? modelContext.save()
            
            // Track error
            if let serviceError = error as? AddVideoServiceError {
                let errorType = mapServiceError(serviceError)
                AddVideoAnalyticsService.shared.trackError(errorType: errorType)
            }
        }
    }
    
    /// Query pending submissions (Task T030)
    func getPendingSubmissions() throws -> [VideoSubmissionRequest] {
        let descriptor = FetchDescriptor<VideoSubmissionRequest>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        
        let all = try modelContext.fetch(descriptor)
        return all.filter { $0.status == .pending || $0.status == .processing }
    }
    
    /// Query failed submissions
    func getFailedSubmissions() throws -> [VideoSubmissionRequest] {
        let descriptor = FetchDescriptor<VideoSubmissionRequest>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        let all = try modelContext.fetch(descriptor)
        return all.filter { $0.status == .failed }
    }
    
    /// Clean up old completed/failed submissions (Task T031)
    func cleanup() async {
        do {
            let twentyFourHoursAgo = Date().addingTimeInterval(-24 * 60 * 60)
            
            // Fetch all submissions and filter
            let allDescriptor = FetchDescriptor<VideoSubmissionRequest>()
            let allSubmissions = try modelContext.fetch(allDescriptor)
            
            // Delete completed submissions older than 24 hours
            let completedSubmissions = allSubmissions.filter { submission in
                submission.status == .completed &&
                submission.updatedAt < twentyFourHoursAgo
            }
            for submission in completedSubmissions {
                modelContext.delete(submission)
            }
            
            // Delete failed submissions (retryCount >= 3) older than 24 hours
            let failedSubmissions = allSubmissions.filter { submission in
                submission.status == .failed &&
                submission.retryCount >= 3 &&
                submission.updatedAt < twentyFourHoursAgo
            }
            for submission in failedSubmissions {
                modelContext.delete(submission)
            }
            
            try modelContext.save()
            
            let totalDeleted = completedSubmissions.count + failedSubmissions.count
            if totalDeleted > 0 {
                print("🧹 Queue: Cleaned up \(totalDeleted) old submissions")
            }
            
        } catch {
            print("❌ Queue: Cleanup error: \(error)")
        }
    }
    
    // MARK: - Connectivity Monitoring (Task T055 integration)
    
    private func setupConnectivityMonitoring() {
        // Monitor connectivity changes
        Task {
            for await isConnected in connectivityMonitor.connectivityStream {
                if isConnected {
                    print("🌐 Queue: Connection restored, processing queue")
                    await processQueue()
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func mapServiceError(_ error: AddVideoServiceError) -> AddVideoEvent.ErrorType {
        switch error {
        case .timeout:
            return .timeout
        case .extractionFailed:
            return .extractionFailed
        case .networkError:
            return .networkError
        case .unsupportedPlatform:
            return .unsupportedPlatform
        case .duplicateVideo:
            return .duplicateVideo
        case .submissionFailed:
            return .submissionFailed
        }
    }
}

// MARK: - ConnectivityMonitor Protocol

/// Protocol for network connectivity monitoring
protocol ConnectivityMonitorProtocol {
    var isConnected: Bool { get }
    var connectivityStream: AsyncStream<Bool> { get }
}

/// Simple connectivity monitor using Network framework
class ConnectivityMonitor: ConnectivityMonitorProtocol {
    
    private(set) var isConnected: Bool = true
    
    private var continuation: AsyncStream<Bool>.Continuation?
    
    lazy var connectivityStream: AsyncStream<Bool> = {
        AsyncStream { continuation in
            self.continuation = continuation
            
            // TODO: Integrate with Network.framework
            // Example:
            // let monitor = NWPathMonitor()
            // monitor.pathUpdateHandler = { path in
            //     let connected = path.status == .satisfied
            //     self.isConnected = connected
            //     continuation.yield(connected)
            // }
            // monitor.start(queue: DispatchQueue.global())
            
            continuation.onTermination = { _ in
                // Cleanup
            }
        }
    }()
    
    func start() {
        // Start monitoring
        _ = connectivityStream
    }
}
