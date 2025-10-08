import SwiftUI
import SwiftData

/// Main video list view displaying vertically scrolling cards with offline support
struct VideoListView: View {
    @StateObject var viewModel: VideoListViewModel
    let authService: AuthService
    let onProfileTap: (() -> Void)?  // Added in: 006-add-a-profile
    @State private var showAddVideoFlow = false
    
    init(viewModel: VideoListViewModel, authService: AuthService, onProfileTap: (() -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.authService = authService
        self.onProfileTap = onProfileTap
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                contentView
                
                // Floating action button (now active - Task T053)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showAddVideoFlow = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .accessibilityLabel(NSLocalizedString("video_list_add_button", comment: ""))
                        .padding(Spacing.stackMedium)
                    }
                }
            }
            .sheet(isPresented: $showAddVideoFlow) {
                AddVideoCoordinator(authService: authService)
            }
            .navigationTitle(NSLocalizedString("video_list_title", comment: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        onProfileTap?()
                    }) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    .accessibilityLabel("Profile")
                    .accessibilityIdentifier("profile_avatar")
                }
            }
            .overlay(alignment: .top) {
                if viewModel.showReconnectToast {
                    reconnectToast
                }
            }
            .task {
                await viewModel.loadCards()
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.loadState {
        case .loading:
            loadingView
            
        case .loaded(let cards):
            cardListView(cards: cards)
            
        case .empty(let message):
            emptyStateView(message: message)
            
        case .error(let message, _):
            errorView(message: message)
            
        case .offline(let cards, let message):
            VStack(spacing: 0) {
                offlineBanner(message: message)
                cardListView(cards: cards)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: Spacing.stackMedium) {
            ProgressView()
                .scaleEffect(1.5)
            Text(NSLocalizedString("video_list_loading", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func cardListView(cards: [VideoCard]) -> some View {
        ScrollView {
            LazyVStack(spacing: Spacing.stackMedium) {
                ForEach(cards) { card in
                    VideoCardView(card: card)
                        .padding(.horizontal, Spacing.stackMedium)
                }
            }
            .padding(.top, Spacing.stackMedium)
            .padding(.bottom, 80) // Space for FAB
        }
    }
    
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: Spacing.stackMedium) {
            Image(systemName: "video.slash")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.stackLarge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.stackMedium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(.red)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.stackLarge)
            
            Button(action: {
                Task {
                    await viewModel.retry()
                }
            }) {
                Text(NSLocalizedString("video_list_retry_button", comment: ""))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.stackLarge)
                    .padding(.vertical, Spacing.stackSmall)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func offlineBanner(message: String) -> some View {
        HStack(spacing: Spacing.stackXSmall) {
            Image(systemName: "wifi.slash")
                .foregroundColor(.white)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, Spacing.stackMedium)
        .padding(.vertical, Spacing.stackSmall)
        .frame(maxWidth: .infinity)
        .background(Color.orange)
    }
    
    private var reconnectToast: some View {
        HStack(spacing: Spacing.stackXSmall) {
            Image(systemName: "wifi")
                .foregroundColor(.white)
            Text(NSLocalizedString("video_list_reconnect_toast", comment: ""))
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding(.horizontal, Spacing.stackMedium)
        .padding(.vertical, Spacing.stackSmall)
        .background(Color.green)
        .cornerRadius(8)
        .shadow(radius: 4)
        .padding(.top, Spacing.stackSmall)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut, value: viewModel.showReconnectToast)
    }
}

#Preview("Loading") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: VideoCardEntity.self, configurations: config)
    
    let viewModel = VideoListViewModel(
        service: MockVideoCardsService(),
        modelContext: container.mainContext
    )
    
    let mockAuthService = AuthService(client: MockAuthClientForPreview())
    
    VideoListView(viewModel: viewModel, authService: mockAuthService)
}

#Preview("Loaded") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: VideoCardEntity.self, configurations: config)
    
    let cards = [
        VideoCard(
            id: UUID(),
            title: "The Future of AI",
            creatorDisplayName: "TechTalks",
            platformDisplayName: "YouTube",
            durationSeconds: 765,
            thumbnailURL: nil,
            updatedAt: Date()
        ),
        VideoCard(
            id: UUID(),
            title: "SwiftUI Advanced Techniques",
            creatorDisplayName: "iOS Dev",
            platformDisplayName: "Vimeo",
            durationSeconds: 1230,
            thumbnailURL: nil,
            updatedAt: Date()
        )
    ]
    
    let service = MockVideoCardsService(mockCards: cards)
    let viewModel = VideoListViewModel(
        service: service,
        modelContext: container.mainContext
    )
    
    let mockAuthService = AuthService(client: MockAuthClientForPreview())
    
    VideoListView(viewModel: viewModel, authService: mockAuthService)
}

// MARK: - Mock Service for Previews

private final class MockVideoCardsService: VideoCardsServiceType, @unchecked Sendable {
    let mockCards: [VideoCard]
    
    init(mockCards: [VideoCard] = []) {
        self.mockCards = mockCards
    }
    
    func fetchCards(limit: Int, cursor: Date?) async throws -> [VideoCardDTO] {
        mockCards.map { card in
            VideoCardDTO(
                id: card.id,
                title: card.title,
                creatorName: card.creatorDisplayName,
                platformName: card.platformDisplayName,
                durationSeconds: card.durationSeconds,
                thumbnailUrl: card.thumbnailURL?.absoluteString,
                updatedAt: card.updatedAt
            )
        }
    }
    
    func subscribeToCardStream(since: Date) -> AsyncThrowingStream<VideoCardStreamEvent, Error> {
        AsyncThrowingStream { _ in }
    }
}

// MARK: - Mock Auth Client for Previews

private class MockAuthClientForPreview: AuthServiceClient {
    var currentSession: AuthClientSession? {
        AuthClientSession(
            userID: UUID(),
            email: "preview@example.com",
            accessTokenExpiresAt: Date().addingTimeInterval(3600),
            refreshToken: "mock-token",
            isVerified: true,
            raw: nil
        )
    }
    
    var sessionUpdates: AsyncStream<AuthClientSession?> {
        AsyncStream { _ in }
    }
    
    func signUp(email: String, password: String, consent: Bool) async throws -> AuthClientSignUpResult {
        .session(currentSession!)
    }
    
    func signIn(email: String, password: String) async throws -> AuthClientSession {
        currentSession!
    }
    
    func signOut() async throws {}
    
    func sendPasswordReset(email: String) async throws {}
    
    func verifyOTP(email: String, token: String, newPassword: String) async throws -> AuthClientSession {
        currentSession!
    }
}
