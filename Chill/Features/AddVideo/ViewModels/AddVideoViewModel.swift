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
    
    // MARK: - Dependencies (will be injected)
    
    // private let addVideoService: AddVideoService
    // private let videoSubmissionQueue: VideoSubmissionQueue
    // private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init() {
        self.urlValidator = URLValidator()
        
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
        // TODO: Query VideoCardEntity by normalizedURL using ModelContext
        // For now, set to false (will implement when SwiftData context is available)
        isDuplicate = false
        
        // Implementation will look like:
        // let descriptor = FetchDescriptor<VideoCardEntity>(
        //     predicate: #Predicate { $0.url == normalizedURL }
        // )
        // let results = try? modelContext.fetch(descriptor)
        // isDuplicate = !(results?.isEmpty ?? true)
    }
    
    // MARK: - Metadata Fetching (Task T035)
    
    func submitURL() {
        guard let result = validationResult, result.isValid else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // TODO: Implement actual LoadifyEngine call via AddVideoService
                // For now, simulate delay
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                // Mock metadata for now
                let mockMetadata = VideoMetadata(
                    title: "Sample Video",
                    description: descriptionInput.isEmpty ? nil : descriptionInput,
                    thumbnailURL: "https://via.placeholder.com/640x360",
                    creator: "Test Creator",
                    platform: result.platform!,
                    duration: 300,
                    publishedDate: nil,
                    videoURL: "https://example.com/video.mp4",
                    size: nil
                )
                
                await MainActor.run {
                    self.fetchedMetadata = mockMetadata
                    self.isLoading = false
                    self.isConfirmationPresented = true
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Unable to fetch video details. Please check the URL and try again."
                }
            }
        }
    }
    
    // MARK: - Final Save (Task T036)
    
    func confirmAndSave() {
        guard let metadata = fetchedMetadata else {
            return
        }
        
        Task {
            do {
                // TODO: Save to Supabase and SwiftData
                // await addVideoService.submit(metadata)
                
                // Simulate save
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                await MainActor.run {
                    // Dismiss both screens
                    self.isConfirmationPresented = false
                    self.resetState()
                    
                    // Emit analytics event
                    self.emitAnalyticsEvent(.videoSaved)
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save video. Please try again."
                }
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
    
    private func emitAnalyticsEvent(_ eventType: AddVideoEventType) {
        // TODO: Integrate with existing analytics pipeline
        print("📊 Analytics: \(eventType.rawValue)")
    }
    
    // MARK: - Test Helpers
    
    func simulateNetworkError() {
        errorMessage = "Network error occurred"
        isLoading = false
    }
}

// MARK: - Supporting Types

enum AddVideoEventType: String {
    case inputModalOpened
    case confirmationScreenOpened
    case videoSaved
    case error
}
