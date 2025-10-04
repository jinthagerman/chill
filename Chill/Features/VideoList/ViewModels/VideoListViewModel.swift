import Foundation
import Combine
import SwiftData
import os

/// View model managing video list state, offline cache, and subscription lifecycle
@MainActor
final class VideoListViewModel: ObservableObject {
    // MARK: - Published State
    
    @Published private(set) var loadState: VideoListLoadState = .loading
    @Published var showReconnectToast: Bool = false
    
    // MARK: - Dependencies
    
    private let service: VideoCardsServiceType
    private let modelContext: ModelContext
    private let logger: Logger
    private let analytics: VideoListAnalytics
    
    // MARK: - Internal State
    
    private var subscriptionTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var hasEmittedPageView = false
    private var isSubscriptionActive = false
    
    // MARK: - Initialization
    
    init(
        service: VideoCardsServiceType,
        modelContext: ModelContext,
        logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.bitcrank.Chill", category: "VideoList"),
        analytics: VideoListAnalytics = .noop
    ) {
        self.service = service
        self.modelContext = modelContext
        self.logger = logger
        self.analytics = analytics
    }
    
    deinit {
        subscriptionTask?.cancel()
    }
    
    // MARK: - Public API
    
    /// Load video cards on view appear
    func loadCards() async {
        guard case .loading = loadState else { return }
        
        // Emit page view analytics once
        if !hasEmittedPageView {
            analytics.trackPageView()
            hasEmittedPageView = true
        }
        
        do {
            // Try fetching from network first
            let dtos = try await service.fetchCards(limit: 50, cursor: nil)
            
            if dtos.isEmpty {
                // Check cache as fallback
                let cachedCards = try loadCachedCards()
                if cachedCards.isEmpty {
                    loadState = .empty(message: NSLocalizedString("video_list_empty", comment: ""))
                } else {
                    loadState = .loaded(cards: cachedCards)
                }
            } else {
                // Persist to cache
                try modelContext.upsertVideoCards(dtos)
                
                // Convert to domain models
                let cards = dtos.compactMap { $0.toCard() }
                loadState = .loaded(cards: cards)
                
                // Start subscription after successful load
                startSubscription(since: Date())
            }
        } catch {
            logger.error("Failed to load cards: \(error.localizedDescription)")
            
            // Fall back to cache on error
            do {
                let cachedCards = try loadCachedCards()
                if cachedCards.isEmpty {
                    loadState = .error(
                        message: NSLocalizedString("video_list_error", comment: ""),
                        retryToken: UUID()
                    )
                } else {
                    loadState = .offline(
                        cards: cachedCards,
                        message: NSLocalizedString("video_list_offline_banner", comment: "")
                    )
                }
            } catch {
                loadState = .error(
                    message: NSLocalizedString("video_list_error", comment: ""),
                    retryToken: UUID()
                )
            }
        }
    }
    
    /// Retry loading after error
    func retry() async {
        loadState = .loading
        await loadCards()
    }
    
    /// Handle network reconnection
    func handleReconnect() {
        guard !isSubscriptionActive else { return }
        
        logger.info("Network reconnected - resuming subscription")
        showReconnectToast = true
        
        // Hide toast after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            showReconnectToast = false
        }
        
        // Reload to sync with server
        Task {
            loadState = .loading
            await loadCards()
        }
    }
    
    // MARK: - Private Helpers
    
    private func loadCachedCards() throws -> [VideoCard] {
        let entities = try modelContext.fetchAllVideoCards()
        return entities.map { $0.toCard() }
    }
    
    private func startSubscription(since: Date) {
        guard subscriptionTask == nil else { return }
        
        isSubscriptionActive = true
        
        subscriptionTask = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let stream = self.service.subscribeToCardStream(since: since)
                
                for try await event in stream {
                    await self.handleStreamEvent(event)
                }
            } catch {
                await MainActor.run {
                    self.logger.error("Subscription error: \(error.localizedDescription)")
                    self.isSubscriptionActive = false
                    
                    // Transition to offline state if we have cached cards
                    if case .loaded(let cards) = self.loadState, !cards.isEmpty {
                        self.loadState = .offline(
                            cards: cards,
                            message: NSLocalizedString("video_list_connection_lost", comment: "")
                        )
                    }
                }
            }
        }
    }
    
    private func handleStreamEvent(_ event: VideoCardStreamEvent) async {
        switch event {
        case .insert(let dto), .update(let dto):
            // Persist to cache
            do {
                try modelContext.upsertVideoCards([dto])
                
                // Reload from cache to update UI
                let cards = try loadCachedCards()
                loadState = .loaded(cards: cards)
            } catch {
                logger.error("Failed to handle stream event: \(error.localizedDescription)")
            }
            
        case .delete(let id):
            // Remove from cache
            do {
                let entityId = id
                let predicate = #Predicate<VideoCardEntity> { $0.id == entityId }
                let descriptor = FetchDescriptor<VideoCardEntity>(predicate: predicate)
                if let entity = try modelContext.fetch(descriptor).first {
                    modelContext.delete(entity)
                    try modelContext.save()
                    
                    // Reload to update UI
                    let cards = try loadCachedCards()
                    if cards.isEmpty {
                        loadState = .empty(message: NSLocalizedString("video_list_empty", comment: ""))
                    } else {
                        loadState = .loaded(cards: cards)
                    }
                }
            } catch {
                logger.error("Failed to delete card: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Load State

enum VideoListLoadState: Equatable {
    case loading
    case loaded(cards: [VideoCard])
    case empty(message: String)
    case error(message: String, retryToken: UUID)
    case offline(cards: [VideoCard], message: String)
    
    static func == (lhs: VideoListLoadState, rhs: VideoListLoadState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.loaded(let lhsCards), .loaded(let rhsCards)):
            return lhsCards == rhsCards
        case (.empty(let lhsMessage), .empty(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.error(let lhsMessage, let lhsToken), .error(let rhsMessage, let rhsToken)):
            return lhsMessage == rhsMessage && lhsToken == rhsToken
        case (.offline(let lhsCards, let lhsMessage), .offline(let rhsCards, let rhsMessage)):
            return lhsCards == rhsCards && lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

// MARK: - Analytics

struct VideoListAnalytics: Sendable {
    private let handler: @Sendable (VideoListEvent) -> Void
    
    nonisolated init(handler: @escaping @Sendable (VideoListEvent) -> Void) {
        self.handler = handler
    }
    
    func trackPageView() {
        handler(.pageView)
    }
    
    nonisolated static let noop = VideoListAnalytics { _ in }
    
    static func live(
        logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.bitcrank.Chill", category: "VideoListAnalytics")
    ) -> VideoListAnalytics {
        return VideoListAnalytics { event in
            switch event {
            case .pageView:
                logger.log("event=video_list.viewed")
            }
        }
    }
}

enum VideoListEvent {
    case pageView
}
