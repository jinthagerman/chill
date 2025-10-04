import Foundation
import Supabase
import Combine

/// Service for fetching video cards from Supabase GraphQL view with subscription support
@preconcurrency protocol VideoCardsServiceType: Sendable {
    /// Fetch initial batch of video cards
    func fetchCards(limit: Int, cursor: Date?) async throws -> [VideoCardDTO]
    
    /// Subscribe to video card stream updates
    func subscribeToCardStream(since: Date) -> AsyncThrowingStream<VideoCardStreamEvent, Error>
}

/// Stream event types from Supabase realtime
enum VideoCardStreamEvent {
    case insert(VideoCardDTO)
    case update(VideoCardDTO)
    case delete(UUID)
}

// MARK: - Live Implementation

/// Actor-isolated service wrapping Supabase client for thread-safe GraphQL operations
actor VideoCardsService: VideoCardsServiceType {
    private let client: SupabaseClient
    private let viewName: String
    
    init(client: SupabaseClient, viewName: String = VideoListConfig.graphQLViewName()) {
        self.client = client
        self.viewName = viewName
    }
    
    /// Fetch video cards via Postgrest (simpler than GraphQL for initial load)
    func fetchCards(limit: Int = 50, cursor: Date? = nil) async throws -> [VideoCardDTO] {
        // Remove "public." prefix if present since .from() adds schema automatically
        let tableName = viewName.replacingOccurrences(of: "public.", with: "")
        
        // Apply ordering and limit (skip cursor for now - pagination can be added later)
        let response: [VideoCardDTO] = try await client.from(tableName)
            .select()
            .order("updated_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return response
    }
    
    /// Subscribe to realtime updates for video cards
    nonisolated func subscribeToCardStream(since: Date) -> AsyncThrowingStream<VideoCardStreamEvent, Error> {
        let client = self.client
        let viewName = self.viewName
        // Remove "public." prefix for realtime subscription
        let tableName = viewName.replacingOccurrences(of: "public.", with: "")
        
        return AsyncThrowingStream<VideoCardStreamEvent, Error> { continuation in
            let channel = client.realtimeV2.channel("video_cards_stream")
            
            let changeHandler: @Sendable (AnyAction) -> Void = { action in
                // Note: We can't call actor methods from @Sendable closure, 
                // so we handle decoding inline
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                switch action {
                case .insert(let insertAction):
                    if let data = try? JSONSerialization.data(withJSONObject: insertAction.record),
                       let dto = try? decoder.decode(VideoCardDTO.self, from: data) {
                        continuation.yield(VideoCardStreamEvent.insert(dto))
                    }
                case .update(let updateAction):
                    if let data = try? JSONSerialization.data(withJSONObject: updateAction.record),
                       let dto = try? decoder.decode(VideoCardDTO.self, from: data) {
                        continuation.yield(VideoCardStreamEvent.update(dto))
                    }
                case .delete(let deleteAction):
                    // Extract UUID from oldRecord (handle AnyJSON type)
                    if let idValue = deleteAction.oldRecord["id"] {
                        // Serialize and deserialize to get string value
                        if let data = try? JSONSerialization.data(withJSONObject: [idValue]),
                           let dict = try? JSONSerialization.jsonObject(with: data) as? [Any],
                           let idString = dict.first as? String,
                           let id = UUID(uuidString: idString) {
                            continuation.yield(VideoCardStreamEvent.delete(id))
                        }
                    }
                }
            }
            
            Task {
                // Subscribe to postgres changes on the view
                _ = channel.onPostgresChange(
                    AnyAction.self,
                    schema: "public",
                    table: tableName
                ) { changeHandler($0) }
                
                // Start listening (note: subscribe() deprecated but subscribeWithError not stable yet)
                await channel.subscribe()
                
                continuation.onTermination = { _ in
                    Task {
                        await channel.unsubscribe()
                    }
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func decodeRecord(_ record: [String: Any]) throws -> VideoCardDTO {
        let data = try JSONSerialization.data(withJSONObject: record)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(VideoCardDTO.self, from: data)
    }
}

// MARK: - Factory

extension VideoCardsService {
    /// Create live service with Supabase client
    static func live(configuration: AuthConfiguration) -> VideoCardsService {
        let client = SupabaseClient(
            supabaseURL: configuration.supabaseURL,
            supabaseKey: configuration.supabaseAnonKey
        )
        return VideoCardsService(client: client)
    }
}

// MARK: - Error Handling

enum VideoCardsServiceError: Error, LocalizedError {
    case networkUnavailable
    case invalidResponse
    case subscriptionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network unavailable. Check your connection."
        case .invalidResponse:
            return "Invalid response from server."
        case .subscriptionFailed(let reason):
            return "Subscription failed: \(reason)"
        }
    }
}
