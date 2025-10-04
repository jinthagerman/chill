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
            contentForRoute
        }
    }

    @ViewBuilder
    private var contentForRoute: some View {
        switch coordinator.route {
        case .welcome:
            WelcomeView(viewModel: coordinator.makeWelcomeViewModel())
        case .auth:
            if let viewModel = coordinator.authViewModel {
                AuthView(viewModel: viewModel)
            } else {
                EmptyView()
            }
        case .savedLinks:
            SavedLinksView()
        case .videoList:
            coordinator.makeVideoListView(modelContext: modelContext)
        }
    }
}

#Preview {
    ContentView()
}
