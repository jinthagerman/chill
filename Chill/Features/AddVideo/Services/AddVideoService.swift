//
//  AddVideoService.swift
//  Chill
//
//  Created by Chill Team on 10/4/25.
//  Feature: 004-implement-add-video
//  Tasks: T024, T025, T026
//

import Foundation
import LoadifyEngine
import Supabase

/// Service for extracting video metadata and submitting to backend
@MainActor
class AddVideoService {
    
    // MARK: - Dependencies
    
    private let loadifyClient: LoadifyClient
    private let supabaseClient: SupabaseClient
    
    // MARK: - Cache
    
    private var metadataCache: [String: VideoMetadata] = [:]
    
    // MARK: - Initialization
    
    init(loadifyClient: LoadifyClient? = nil, supabaseClient: SupabaseClient? = nil) {
        self.loadifyClient = loadifyClient ?? LoadifyClient()
        
        // Use existing Supabase client or create from AuthConfiguration
        if let client = supabaseClient {
            self.supabaseClient = client
        } else {
            // Load from xcconfig via AuthConfiguration (same as auth system)
            do {
                let configuration = try AuthConfiguration.load()
                self.supabaseClient = SupabaseClient(
                    supabaseURL: configuration.supabaseURL,
                    supabaseKey: configuration.supabaseAnonKey
                )
            } catch {
                fatalError("Failed to load Supabase configuration: \(error)")
            }
        }
    }
    
    // MARK: - Metadata Extraction (Task T025)
    
    /// Extracts video metadata from URL using LoadifyEngine
    /// - Parameter url: The video URL to extract from
    /// - Returns: VideoMetadata containing title, thumbnail, creator, etc.
    /// - Throws: AddVideoServiceError for failures
    func extractMetadata(from url: String) async throws -> VideoMetadata {
        // Check cache first
        let normalizedURL = URLValidator().normalizeURL(url)
        if let cached = metadataCache[normalizedURL] {
            return cached
        }
        
        // Set 10 second timeout
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            throw AddVideoServiceError.timeout
        }
        
        let fetchTask = Task {
            try await loadifyClient.fetchVideoDetails(for: url)
        }
        
        // Race timeout vs fetch
        let result = await Task.select(timeout: timeoutTask, fetch: fetchTask)
        
        let loadifyResponse: LoadifyResponse
        switch result {
        case .timeout:
            fetchTask.cancel()
            throw AddVideoServiceError.timeout
        case .fetch(let response):
            timeoutTask.cancel()
            switch response {
            case .success(let data):
                loadifyResponse = data
            case .failure(let error):
                throw AddVideoServiceError.extractionFailed
            }
        }
        
        // Validate platform support (Facebook and Twitter only)
        guard loadifyResponse.platform == .facebook || loadifyResponse.platform == .twitter else {
            throw AddVideoServiceError.unsupportedPlatform
        }
        
        // Map LoadifyResponse to VideoMetadata
        let metadata = VideoMetadata.from(loadifyResponse: loadifyResponse, originalURL: url)
        
        // Cache for future requests
        metadataCache[normalizedURL] = metadata
        
        return metadata
    }
    
    // MARK: - Supabase Submission (Task T026)
    
    /// Submits video metadata to Supabase backend
    /// - Parameters:
    ///   - metadata: The video metadata to submit
    ///   - userNotes: Optional user-provided notes
    ///   - userId: The user ID (from auth session)
    ///   - originalURL: The original video URL
    /// - Returns: The created video ID
    /// - Throws: AddVideoServiceError for submission failures
    func submitToSupabase(
        metadata: VideoMetadata,
        userNotes: String?,
        userId: UUID,
        originalURL: String
    ) async throws -> UUID {
        
        // Prepare submission payload matching actual Supabase schema
        // Note: user_id is omitted - Supabase RLS auto-injects it from auth.uid()
        let submission = VideoSubmissionPayload(
            originalURL: originalURL,
            downloadURL: metadata.videoURL,
            title: metadata.title,
            description: metadata.videoDescription, // From video metadata
            note: userNotes, // From user input (singular 'note' in schema)
            thumbnailURL: metadata.thumbnailURL,
            creatorUsername: metadata.creator,
            creatorProfileImageURL: nil, // LoadifyEngine doesn't provide this
            platform: metadata.platform.rawValue,
            platformVideoId: nil, // Could extract from URL in future
            lengthSeconds: metadata.duration,
            fileSizeBytes: metadata.size != nil ? Int(metadata.size!) : nil
        )
        
        do {
            // Submit to Supabase 'videos' table
            let response: VideoSubmissionResponse = try await supabaseClient
                .from("videos")
                .insert(submission)
                .select()
                .single()
                .execute()
                .value
            
            return response.id
            
        } catch {
            // Handle Supabase-specific errors
            if let supabaseError = error as? PostgrestError {
                switch supabaseError.code {
                case "23505": // Unique constraint violation
                    throw AddVideoServiceError.duplicateVideo
                default:
                    throw AddVideoServiceError.submissionFailed(supabaseError.message)
                }
            }
            
            throw AddVideoServiceError.networkError
        }
    }
    
    // MARK: - Combined Flow
    
    /// Full submission flow: extract metadata + submit to backend
    /// - Parameters:
    ///   - url: Video URL to extract and submit
    ///   - userNotes: Optional notes from user
    ///   - userId: Current user ID
    /// - Returns: Tuple of (videoId, metadata)
    func extractAndSubmit(
        url: String,
        userNotes: String?,
        userId: UUID
    ) async throws -> (videoId: UUID, metadata: VideoMetadata) {
        
        // Step 1: Extract metadata
        let metadata = try await extractMetadata(from: url)
        
        // Step 2: Submit to Supabase
        let videoId = try await submitToSupabase(
            metadata: metadata,
            userNotes: userNotes,
            userId: userId,
            originalURL: url
        )
        
        return (videoId, metadata)
    }
}

// MARK: - Supporting Types

/// Errors that can occur during video submission
enum AddVideoServiceError: Error, Equatable, LocalizedError {
    case timeout
    case extractionFailed
    case networkError
    case unsupportedPlatform
    case duplicateVideo
    case submissionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Request timed out. Please try again."
        case .extractionFailed:
            return "Unable to extract video details. Please check the URL."
        case .networkError:
            return "Network error. Please check your connection."
        case .unsupportedPlatform:
            return "Only Facebook and Twitter videos are supported."
        case .duplicateVideo:
            return "This video is already in your library."
        case .submissionFailed(let message):
            return "Submission failed: \(message)"
        }
    }
}

/// Payload for Supabase video submission
/// Note: user_id is NOT included - Supabase auto-injects it from auth.uid() via RLS
struct VideoSubmissionPayload: Encodable {
    let originalURL: String
    let downloadURL: String?
    let title: String?
    let description: String? // From video metadata (if available)
    let note: String? // From user input (singular 'note' per schema)
    let thumbnailURL: String?
    let creatorUsername: String?
    let creatorProfileImageURL: String?
    let platform: String
    let platformVideoId: String?
    let lengthSeconds: Int?
    let fileSizeBytes: Int?
    
    enum CodingKeys: String, CodingKey {
        case originalURL = "original_url"
        case downloadURL = "download_url"
        case title
        case description
        case note
        case thumbnailURL = "thumbnail_url"
        case creatorUsername = "creator_username"
        case creatorProfileImageURL = "creator_profile_image_url"
        case platform
        case platformVideoId = "platform_video_id"
        case lengthSeconds = "length_seconds"
        case fileSizeBytes = "file_size_bytes"
    }
}

/// Response from Supabase after video submission
struct VideoSubmissionResponse: Decodable {
    let id: UUID
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
    }
}

// MARK: - Task Helpers

extension Task where Success == Never, Failure == Never {
    enum SelectResult<TimeoutSuccess, FetchSuccess> {
        case timeout(Result<TimeoutSuccess, Error>)
        case fetch(Result<FetchSuccess, Error>)
    }
    
    static func select<T, U>(
        timeout: Task<T, Error>,
        fetch: Task<U, Error>
    ) async -> SelectResult<T, U> {
        await withTaskGroup(of: SelectResult<T, U>.self) { group in
            group.addTask {
                do {
                    let result = try await timeout.value
                    return .timeout(.success(result))
                } catch {
                    return .timeout(.failure(error))
                }
            }
            
            group.addTask {
                do {
                    let result = try await fetch.value
                    return .fetch(.success(result))
                } catch {
                    return .fetch(.failure(error))
                }
            }
            
            // Return first result
            return await group.next()!
        }
    }
}
