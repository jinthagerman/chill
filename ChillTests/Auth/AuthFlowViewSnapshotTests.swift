import SnapshotTesting
import SwiftUI
import XCTest
@testable import Chill

@MainActor
final class AuthFlowViewSnapshotTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        isRecording = false
    }

    func testLoginFlowLayout() {
        let service = AuthServiceStub()
        let viewModel = AuthViewModel(
            service: service,
            initialMode: .login,
            networkStatus: .wifi,
            onAuthenticated: { }
        )
        viewModel.email = "login@example.com"
        viewModel.password = "password123"

        let view = AuthView(viewModel: viewModel)

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
    }

    func testSignupFlowLayout() {
        let service = AuthServiceStub()
        let viewModel = AuthViewModel(
            service: service,
            initialMode: .signup(consentAccepted: true),
            networkStatus: .wifi,
            onAuthenticated: { }
        )
        viewModel.email = "signup@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"

        let view = AuthView(viewModel: viewModel)

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
    }

    func testErrorBannerLayout() {
        let service = AuthServiceStub()
        let viewModel = AuthViewModel(
            service: service,
            initialMode: .login,
            networkStatus: .wifi,
            onAuthenticated: { }
        )
        viewModel.errorMessage = "Something went wrong"
        viewModel.statusBanner = AuthBanner(type: .error, message: "Invalid credentials")

        let view = AuthView(viewModel: viewModel)

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
    }
}
