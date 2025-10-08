import Foundation
import Network
import Combine
import SwiftUI
import SwiftData
import Supabase  // Added in: 006-add-a-profile

@MainActor
final class AuthCoordinator: ObservableObject {
    enum Route {
        case welcome
        case auth
        case savedLinks
        case videoList
        case profile  // Added in: 006-add-a-profile
    }

    enum BootstrapState {
        case loading
        case ready
        case failure(String)
    }

    @Published private(set) var route: Route = .welcome
    @Published private(set) var state: BootstrapState = .loading

    private(set) var authViewModel: AuthViewModel?
    private var authService: AuthService?
    private var reachabilityObserver: ReachabilityObserver?

    init() {
        bootstrap()
    }

    private func bootstrap() {
        do {
            let configuration = try AuthConfiguration.load()
            let service = AuthService.live(configuration: configuration)
            authService = service

            let viewModel = AuthViewModel(service: service) { [weak self] in
                self?.route = .videoList
            }
            authViewModel = viewModel
            reachabilityObserver = ReachabilityObserver { [weak viewModel] status in
                viewModel?.updateNetworkStatus(status)
            }

            if service.currentSession != nil {
                route = .videoList
            } else {
                route = .welcome
            }

            state = .ready
        } catch {
            let message: String
            if let configError = error as? AuthConfiguration.ConfigurationError,
               let description = configError.errorDescription {
                message = description
            } else {
                message = "Supabase configuration failed: \(error.localizedDescription)"
            }
            state = .failure(message)
        }
    }

    func makeWelcomeViewModel() -> WelcomeViewModel {
        WelcomeViewModel(
            buttonState: .active(loginPermitted: true, signupPermitted: true),
            onLoginSelected: { [weak self] in
                self?.presentAuth(mode: .login)
            },
            onSignupSelected: { [weak self] in
                self?.presentAuth(mode: .signup(consentAccepted: false))
            }
        )
    }
    
    func makeVideoListView(modelContext: ModelContext) -> VideoListView {
        guard let authService = authService else {
            fatalError("AuthService not initialized")
        }
        
        do {
            let configuration = try AuthConfiguration.load()
            let service = VideoCardsService.live(configuration: configuration)
            let viewModel = VideoListViewModel(
                service: service,
                modelContext: modelContext
            )
            return VideoListView(
                viewModel: viewModel,
                authService: authService,
                onProfileTap: { [weak self] in
                    self?.presentProfile()
                }
            )
        } catch {
            fatalError("Failed to initialize VideoListView: \(error)")
        }
    }
    
    /// Create and present the profile view
    /// Added in: 006-add-a-profile
    func makeProfileView() -> ProfileView {
        guard let authService = authService else {
            fatalError("AuthService not initialized")
        }
        
        do {
            let configuration = try AuthConfiguration.load()
            // Create new Supabase client for profile services
            let supabaseClient = SupabaseClient(
                supabaseURL: configuration.supabaseURL,
                supabaseKey: configuration.supabaseAnonKey
            )
            let profileService = ProfileService(client: supabaseClient)
            let settingsService = SettingsService(client: supabaseClient)
            let profileViewModel = ProfileViewModel(
                profileService: profileService,
                authService: authService
            )
            
            return ProfileView(
                viewModel: profileViewModel,
                settingsService: settingsService,
                authService: authService,
                onDismiss: { [weak self] in
                    self?.dismissProfile()
                },
                onSignOut: { [weak self] in
                    await self?.signOut()
                }
            )
        } catch {
            fatalError("Failed to initialize ProfileView: \(error)")
        }
    }
    
    /// Navigate to profile page
    /// Added in: 006-add-a-profile
    func presentProfile() {
        route = .profile
    }
    
    /// Dismiss profile and return to video list
    /// Added in: 006-add-a-profile
    func dismissProfile() {
        route = .videoList
    }

    func presentAuth(mode: AuthMode) {
        guard let viewModel = authViewModel else { return }
        resetInputs(for: mode, viewModel: viewModel)
        viewModel.updateMode(mode)
        route = .auth
    }

    func signOut() async {
        guard let service = authService else { return }
        do {
            try await service.signOut()
            route = .welcome
        } catch {
            // Optionally surface sign-out errors in future polish tasks.
        }
    }

private func resetInputs(for mode: AuthMode, viewModel: AuthViewModel) {
        viewModel.email = ""
        viewModel.password = ""
        viewModel.errorMessage = nil
        viewModel.statusBanner = nil
        viewModel.otpCode = ""

        switch mode {
        case .signup:
            viewModel.confirmPassword = ""
        case .resetRequest:
            break
        case .resetVerify:
            break
        case .login:
            viewModel.confirmPassword = ""
        }
    }
}

private final class ReachabilityObserver {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.bitcrank.chill.reachability")
    private let handler: (NetworkReachability) -> Void

    init(handler: @escaping (NetworkReachability) -> Void) {
        self.handler = handler
        monitor.pathUpdateHandler = { path in
            let status: NetworkReachability
            if path.status == .satisfied {
                if path.usesInterfaceType(.wifi) {
                    status = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    status = .cellular
                } else {
                    status = .wifi
                }
            } else {
                status = .offline
            }

            DispatchQueue.main.async {
                handler(status)
            }
        }

        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
