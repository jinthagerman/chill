import Foundation
import SwiftData

/// SwiftData persistent model for video card summaries, enabling offline browsing.
/// Each entity represents a video card from the curated Supabase GraphQL view.
@Model
final class VideoCardEntity {
    @Attribute(.unique) var id: UUID
    var title: String
    var creatorDisplayName: String
    var platformDisplayName: String
    var durationSeconds: Int
    var thumbnailURL: URL?
    var updatedAt: Date
    var syncedAt: Date
    
    init(
        id: UUID,
        title: String,
        creatorDisplayName: String,
        platformDisplayName: String,
        durationSeconds: Int,
        thumbnailURL: URL?,
        updatedAt: Date,
        syncedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.creatorDisplayName = creatorDisplayName
        self.platformDisplayName = platformDisplayName
        self.durationSeconds = max(0, min(durationSeconds, 12 * 60 * 60)) // Clamp 0...12h
        self.thumbnailURL = thumbnailURL
        self.updatedAt = updatedAt
        self.syncedAt = syncedAt
    }
    
    /// Formatted duration string (mm:ss)
    var durationLabel: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Accessibility label for VoiceOver
    var accessibilityLabel: String {
        "\(title), \(creatorDisplayName), \(durationLabel)"
    }
}

// MARK: - Domain Model Mapping

/// Immutable domain model for SwiftUI rendering
struct VideoCard: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let creatorDisplayName: String
    let platformDisplayName: String
    let durationSeconds: Int
    let thumbnailURL: URL?
    let updatedAt: Date
    
    var durationLabel: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var accessibilityLabel: String {
        "\(title), \(creatorDisplayName), \(durationLabel)"
    }
}

extension VideoCardEntity {
    /// Convert persistent entity to immutable domain model
    func toCard() -> VideoCard {
        VideoCard(
            id: id,
            title: title,
            creatorDisplayName: creatorDisplayName,
            platformDisplayName: platformDisplayName,
            durationSeconds: durationSeconds,
            thumbnailURL: thumbnailURL,
            updatedAt: updatedAt
        )
    }
}

// MARK: - GraphQL DTO Mapping

/// DTO for decoding GraphQL query and subscription payloads
@preconcurrency
struct VideoCardDTO: Sendable, Codable {
    let id: UUID
    let title: String
    let creatorName: String?
    let platformName: String
    let durationSeconds: Int
    let thumbnailUrl: String?
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case creatorName = "creator_name"
        case platformName = "platform_name"
        case durationSeconds = "duration_seconds"
        case thumbnailUrl = "thumbnail_url"
        case updatedAt = "updated_at"
    }
    
    // Memberwise initializer for creating DTOs programmatically
    nonisolated init(id: UUID, title: String, creatorName: String?, platformName: String, durationSeconds: Int, thumbnailUrl: String?, updatedAt: Date) {
        self.id = id
        self.title = title
        self.creatorName = creatorName
        self.platformName = platformName
        self.durationSeconds = durationSeconds
        self.thumbnailUrl = thumbnailUrl
        self.updatedAt = updatedAt
    }
    
    
    /// Map DTO to domain model with validation
    func toCard() -> VideoCard? {
        // Reject invalid required fields
        guard !title.isEmpty, !platformName.isEmpty else { return nil }
        
        // Normalize thumbnail URL (require https)
        let normalizedURL: URL?
        if let urlString = thumbnailUrl,
           let url = URL(string: urlString),
           url.scheme == "https" {
            normalizedURL = url
        } else {
            normalizedURL = nil
        }
        
        return VideoCard(
            id: id,
            title: title,
            creatorDisplayName: creatorName?.isEmpty == false ? creatorName! : "Unknown creator",
            platformDisplayName: platformName,
            durationSeconds: max(0, min(durationSeconds, 12 * 60 * 60)),
            thumbnailURL: normalizedURL,
            updatedAt: updatedAt
        )
    }
    
    /// Map DTO to SwiftData entity
    func toEntity() -> VideoCardEntity? {
        guard let card = toCard() else { return nil }
        return VideoCardEntity(
            id: card.id,
            title: card.title,
            creatorDisplayName: card.creatorDisplayName,
            platformDisplayName: card.platformDisplayName,
            durationSeconds: card.durationSeconds,
            thumbnailURL: card.thumbnailURL,
            updatedAt: card.updatedAt
        )
    }
}

// MARK: - Persistence Helpers

extension ModelContext {
    /// Upsert video card entities, replacing existing entries with same ID
    /// - Parameter dtos: DTOs from GraphQL query or subscription
    /// - Returns: Number of entities persisted
    @discardableResult
    func upsertVideoCards(_ dtos: [VideoCardDTO]) throws -> Int {
        var upsertedCount = 0
        
        for dto in dtos {
            guard let entity = dto.toEntity() else {
                // Log warning: rejected payload missing required fields
                continue
            }
            
            // Check if entity already exists
            let entityId = entity.id
            let predicate = #Predicate<VideoCardEntity> { $0.id == entityId }
            let existingFetch = FetchDescriptor<VideoCardEntity>(predicate: predicate)
            
            if let existing = try fetch(existingFetch).first {
                // Only update if new data is fresher (monotonic guard)
                guard entity.updatedAt >= existing.updatedAt else { continue }
                
                existing.title = entity.title
                existing.creatorDisplayName = entity.creatorDisplayName
                existing.platformDisplayName = entity.platformDisplayName
                existing.durationSeconds = entity.durationSeconds
                existing.thumbnailURL = entity.thumbnailURL
                existing.updatedAt = entity.updatedAt
                existing.syncedAt = Date()
            } else {
                insert(entity)
            }
            
            upsertedCount += 1
        }
        
        try save()
        return upsertedCount
    }
    
    /// Fetch all cached video cards ordered by updatedAt descending
    func fetchAllVideoCards() throws -> [VideoCardEntity] {
        let descriptor = FetchDescriptor<VideoCardEntity>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try fetch(descriptor)
    }
    
    /// Remove cards not synced within the specified number of days
    /// - Parameter days: Purge threshold (defaults to VideoListConfig.cachePurgeDays)
    @discardableResult
    func purgeStaleVideoCards(olderThanDays days: Int = VideoListConfig.cachePurgeDays) throws -> Int {
        let threshold = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = #Predicate<VideoCardEntity> { $0.syncedAt < threshold }
        
        let descriptor = FetchDescriptor<VideoCardEntity>(predicate: predicate)
        let staleEntities = try fetch(descriptor)
        
        for entity in staleEntities {
            delete(entity)
        }
        
        try save()
        return staleEntities.count
    }
}
