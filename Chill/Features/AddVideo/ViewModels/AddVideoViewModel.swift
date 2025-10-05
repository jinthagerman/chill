//
//  AddVideoViewModel.swift
//  Chill
//
//  Created by Chill Team on 10/4/25.
//  Feature: 004-implement-add-video
//  Tasks: T032-T038
//

import Foundation
import Combine
import SwiftUI
import SwiftData

/// ViewModel managing the add video two-step flow
@MainActor
class AddVideoViewModel: ObservableObject {
    
    // MARK: - Published Properties (Input View)
    
    @Published var urlInput: String = ""
    @Published var descriptionInput: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isDuplicate: Bool = false
    
    // MARK: - Published Properties (Confirmation View)
    
    @Published var fetchedMetadata: VideoMetadata?
    @Published var isConfirmationPresented: Bool = false
    
    // MARK: - Computed Properties
    
    var isSaveButtonEnabled: Bool {
        !urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && validationResult?.isValid == true
    }
    
    // MARK: - Private Properties
    
    private var validationResult: URLValidationResult?
    private let urlValidator: URLValidator
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Dependencies
    
    private let addVideoService: AddVideoService
    private let videoSubmissionQueue: VideoSubmissionQueue?
    private let modelContext: ModelContext?
    private let authService: AuthService
    
    /// Current user ID from auth session
    private var userId: UUID {
        authService.currentSession?.userID ?? UUID() // Fallback to temp UUID if not logged in
    }
    
    // MARK: - Initialization
    
    init(
        addVideoService: AddVideoService? = nil,
        videoSubmissionQueue: VideoSubmissionQueue? = nil,
        modelContext: ModelContext? = nil,
        authService: AuthService
    ) {
        self.urlValidator = URLValidator()
        self.addVideoService = addVideoService ?? AddVideoService()
        self.videoSubmissionQueue = videoSubmissionQueue
        self.modelContext = modelContext
        self.authService = authService
        
        setupValidation()
    }
    
    // MARK: - Setup (Task T032, T033)
    
    private func setupValidation() {
        // Real-time validation with 300ms debounce
        $urlInput
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] url in
                self?.validateURL(url)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation (Task T033)
    
    private func validateURL(_ url: String) {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            validationResult = nil
            errorMessage = nil
            isDuplicate = false
            return
        }
        
        // Validate URL format
        validationResult = urlValidator.validate(trimmed)
        
        if let result = validationResult {
            if result.isValid {
                errorMessage = nil
                // Check for duplicates (Task T034)
                checkForDuplicate(normalizedURL: result.normalizedURL ?? "")
            } else {
                errorMessage = result.errorMessage
                isDuplicate = false
            }
        }
    }
    
    // MARK: - Duplicate Detection (Task T034)
    
    private func checkForDuplicate(normalizedURL: String) {
        // TODO: Implement proper duplicate detection when video storage schema is ready
        // For now, we skip duplicate checking since VideoCardEntity doesn't store URLs
        // This will be implemented once the Supabase videos table includes normalized URLs
        
        // Future implementation:
        // 1. Query Supabase videos table by normalized_url
        // 2. Or add normalized_url field to VideoCardEntity
        // 3. Show warning if duplicate found, but still allow save (per spec)
        
        isDuplicate = false
    }
    
    // MARK: - Metadata Fetching (Task T035)
    
    func submitURL() {
        guard let result = validationResult, result.isValid else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let startTime = Date()
        
        Task {
            do {
                // Track URL submission
                AddVideoAnalyticsService.shared.trackURLSubmitted(platform: result.platform!.displayName)
                
                // Extract metadata using AddVideoService
                let metadata = try await addVideoService.extractMetadata(from: urlInput)
                
                let duration = Int(Date().timeIntervalSince(startTime) * 1000)
                
                await MainActor.run {
                    self.fetchedMetadata = metadata
                    self.isLoading = false
                    self.isConfirmationPresented = true
                    
                    // Track successful metadata fetch
                    AddVideoAnalyticsService.shared.trackMetadataFetched(
                        platform: metadata.platform.displayName,
                        durationMs: duration
                    )
                    AddVideoAnalyticsService.shared.trackConfirmationOpened()
                }
                
            } catch let error as AddVideoServiceError {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    
                    // Track error
                    let errorType = mapServiceErrorToAnalytics(error)
                    AddVideoAnalyticsService.shared.trackError(
                        errorType: errorType,
                        platform: result.platform?.displayName
                    )
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Unable to fetch video details. Please check the URL and try again."
                    
                    AddVideoAnalyticsService.shared.trackError(errorType: .unknownError)
                }
            }
        }
    }
    
    // MARK: - Final Save (Task T036)
    
    func confirmAndSave() {
        guard let metadata = fetchedMetadata else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Submit to Supabase via AddVideoService
                let videoId = try await addVideoService.submitToSupabase(
                    metadata: metadata,
                    userNotes: descriptionInput.isEmpty ? nil : descriptionInput,
                    userId: userId,
                    originalURL: urlInput
                )
                
                await MainActor.run {
                    self.isLoading = false
                    self.isConfirmationPresented = false
                    self.resetState()
                    
                    // Track success
                    AddVideoAnalyticsService.shared.trackVideoSaved(platform: metadata.platform.displayName)
                    
                    print("✅ Video saved successfully: \(videoId)")
                }
                
            } catch let error as AddVideoServiceError {
                // If network error and queue is available, queue for offline submission
                if case .networkError = error, let queue = videoSubmissionQueue {
                    await queueOfflineSubmission(metadata: metadata)
                } else {
                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = error.localizedDescription
                        
                        let errorType = mapServiceErrorToAnalytics(error)
                        AddVideoAnalyticsService.shared.trackError(
                            errorType: errorType,
                            platform: metadata.platform.displayName
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to save video. Please try again."
                    
                    AddVideoAnalyticsService.shared.trackError(errorType: .unknownError)
                }
            }
        }
    }
    
    // Queue for offline submission
    private func queueOfflineSubmission(metadata: VideoMetadata) async {
        guard let queue = videoSubmissionQueue,
              let normalizedURL = validationResult?.normalizedURL else {
            return
        }
        
        do {
            let submission = try queue.createSubmission(
                originalURL: urlInput,
                normalizedURL: normalizedURL,
                userProvidedDescription: descriptionInput.isEmpty ? nil : descriptionInput,
                userId: userId
            )
            
            await MainActor.run {
                self.isLoading = false
                self.isConfirmationPresented = false
                self.resetState()
                
                print("📥 Video queued for offline submission: \(submission.id)")
                // TODO: Show toast notification "Video queued, will sync when online"
            }
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to queue video for offline submission."
            }
        }
    }
    
    // MARK: - Navigation Coordination (Task T037)
    
    func cancelInput() {
        resetState()
    }
    
    func closeConfirmation() {
        isConfirmationPresented = false
        resetState()
    }
    
    func returnToEdit() {
        // Task: "Edit Details" - return to input modal with pre-filled data
        isConfirmationPresented = false
        // Keep urlInput and descriptionInput as-is for editing
    }
    
    private func resetState() {
        urlInput = ""
        descriptionInput = ""
        errorMessage = nil
        isDuplicate = false
        fetchedMetadata = nil
        validationResult = nil
    }
    
    // MARK: - Analytics (Task T038)
    
    private func mapServiceErrorToAnalytics(_ error: AddVideoServiceError) -> AddVideoEvent.ErrorType {
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
    
    // MARK: - Test Helpers
    
    func simulateNetworkError() {
        errorMessage = "Network error occurred"
        isLoading = false
    }
}
