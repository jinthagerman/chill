import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var coordinator = AuthCoordinator()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        switch coordinator.state {
        case .loading:
            ProgressView("Preparing Chill...")
                .progressViewStyle(.circular)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failure(let message):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                Text("Configuration Issue")
                    .font(.title2.weight(.semibold))
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        case .ready:
            NavigationStack(path: $coordinator.navigationPath) {
                rootView
                    .navigationDestination(for: AuthCoordinator.Route.self) { route in
                        destinationView(for: route)
                    }
            }
        }
    }
    
    @ViewBuilder
    private var rootView: some View {
        // Root is always welcome or videoList depending on auth state
        switch coordinator.route {
        case .welcome:
            WelcomeView(viewModel: coordinator.makeWelcomeViewModel())
        case .videoList:
            coordinator.makeVideoListView(modelContext: modelContext)
        default:
            // Fallback shouldn't happen
            WelcomeView(viewModel: coordinator.makeWelcomeViewModel())
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: AuthCoordinator.Route) -> some View {
        switch route {
        case .auth:
            if let viewModel = coordinator.authViewModel {
                AuthFlowCoordinator(viewModel: viewModel)
            } else {
                EmptyView()
            }
        case .profile:
            coordinator.makeProfileView()
        case .savedLinks:
            SavedLinksView()
        case .welcome, .videoList:
            EmptyView() // These are handled as root
        }
    }
}

#Preview {
    ContentView()
}
