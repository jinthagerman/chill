import Foundation
import SwiftData
import os

/// Manager for video card cache lifecycle operations including hydration and purging
@MainActor
final class VideoCardCacheManager {
    private let modelContext: ModelContext
    private let logger: Logger
    
    init(
        modelContext: ModelContext,
        logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.bitcrank.Chill", category: "VideoCardCache")
    ) {
        self.modelContext = modelContext
        self.logger = logger
    }
    
    /// Hydrate cache with fresh data from service
    /// - Parameters:
    ///   - dtos: Fresh DTOs from GraphQL query
    ///   - purgeDays: Number of days after which to purge stale entries (defaults to config)
    func hydrate(with dtos: [VideoCardDTO], purgeDays: Int = VideoListConfig.cachePurgeDays) async throws {
        logger.info("Hydrating cache with \(dtos.count) cards")
        
        // Upsert new data
        let upsertedCount = try modelContext.upsertVideoCards(dtos)
        logger.info("Upserted \(upsertedCount) cards to cache")
        
        // Purge stale entries
        let purgedCount = try modelContext.purgeStaleVideoCards(olderThanDays: purgeDays)
        if purgedCount > 0 {
            logger.info("Purged \(purgedCount) stale cards from cache")
        }
    }
    
    /// Purge stale cache entries older than configured threshold
    /// - Parameter days: Number of days (defaults to VideoListConfig.cachePurgeDays)
    /// - Returns: Number of entries purged
    @discardableResult
    func purgeStaleEntries(olderThanDays days: Int = VideoListConfig.cachePurgeDays) async throws -> Int {
        let purgedCount = try modelContext.purgeStaleVideoCards(olderThanDays: days)
        
        if purgedCount > 0 {
            logger.info("Purged \(purgedCount) stale cards (threshold: \(days) days)")
        }
        
        return purgedCount
    }
    
    /// Get cache statistics for debugging and monitoring
    func statistics() async throws -> CacheStatistics {
        let allCards = try modelContext.fetchAllVideoCards()
        
        let now = Date()
        let threshold = Calendar.current.date(byAdding: .day, value: -VideoListConfig.cachePurgeDays, to: now) ?? now
        
        let staleCount = allCards.filter { $0.syncedAt < threshold }.count
        let freshCount = allCards.count - staleCount
        
        return CacheStatistics(
            totalEntries: allCards.count,
            freshEntries: freshCount,
            staleEntries: staleCount,
            oldestSyncDate: allCards.map(\.syncedAt).min(),
            newestSyncDate: allCards.map(\.syncedAt).max()
        )
    }
    
    /// Clear entire cache (use with caution)
    func clearAll() async throws {
        let allCards = try modelContext.fetchAllVideoCards()
        
        for card in allCards {
            modelContext.delete(card)
        }
        
        try modelContext.save()
        logger.warning("Cleared all cache entries (\(allCards.count) cards)")
    }
}

// MARK: - Cache Statistics

struct CacheStatistics {
    let totalEntries: Int
    let freshEntries: Int
    let staleEntries: Int
    let oldestSyncDate: Date?
    let newestSyncDate: Date?
    
    var description: String {
        """
        Cache Statistics:
        - Total entries: \(totalEntries)
        - Fresh entries: \(freshEntries)
        - Stale entries: \(staleEntries)
        - Oldest sync: \(oldestSyncDate?.formatted() ?? "N/A")
        - Newest sync: \(newestSyncDate?.formatted() ?? "N/A")
        """
    }
}

// MARK: - Scheduled Maintenance

extension VideoCardCacheManager {
    /// Run periodic maintenance to purge stale entries
    /// Call this method on app launch or during background refresh
    func performScheduledMaintenance() async {
        do {
            let stats = try await statistics()
            logger.info("Pre-maintenance cache: total=\(stats.totalEntries) fresh=\(stats.freshEntries) stale=\(stats.staleEntries)")
            
            if stats.staleEntries > 0 {
                let purgedCount = try await purgeStaleEntries()
                logger.info("Maintenance purged \(purgedCount) stale entries")
            } else {
                logger.info("No maintenance needed - cache is fresh")
            }
        } catch {
            logger.error("Scheduled maintenance failed: \(error.localizedDescription)")
        }
    }
}
