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
    
    // MARK: - New View Snapshot Tests (T007)
    // Based on: specs/005-split-login-and/quickstart.md Scenarios 1, 2, 5
    
    func testChoiceViewAppearance() {
        // NOTE: This test will FAIL until AuthChoiceView is fully implemented
        let service = AuthServiceStub()
        let viewModel = AuthViewModel(
            service: service,
            initialMode: .login,
            networkStatus: .wifi,
            onAuthenticated: { }
        )
        
        // When navigationState is implemented:
        // viewModel.navigationState = .choice
        
        let view = AuthChoiceView(viewModel: viewModel)
        
        // This will fail with current placeholder view
        // assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
        
        // Temporary placeholder assertion
        XCTFail("AuthChoiceView not fully implemented yet - snapshot will differ")
    }
    
    func testLoginViewAppearance() {
        // NOTE: This test will FAIL until AuthLoginView is fully implemented
        let service = AuthServiceStub()
        let viewModel = AuthViewModel(
            service: service,
            initialMode: .login,
            networkStatus: .wifi,
            onAuthenticated: { }
        )
        
        // When navigationState is implemented:
        // viewModel.navigationState = .login
        
        let view = AuthLoginView(viewModel: viewModel)
        
        // This will fail with current placeholder view
        // assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
        
        // Temporary placeholder assertion
        XCTFail("AuthLoginView not fully implemented yet - snapshot will differ")
    }
    
    func testSignupViewAppearance() {
        // NOTE: This test will FAIL until AuthSignupView is fully implemented
        let service = AuthServiceStub()
        let viewModel = AuthViewModel(
            service: service,
            initialMode: .login,
            networkStatus: .wifi,
            onAuthenticated: { }
        )
        
        // When navigationState is implemented:
        // viewModel.navigationState = .signup(consentAccepted: false)
        
        let view = AuthSignupView(viewModel: viewModel)
        
        // This will fail with current placeholder view
        // assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
        
        // Temporary placeholder assertion
        XCTFail("AuthSignupView not fully implemented yet - snapshot will differ")
    }
    
    func testLoginViewWithError() {
        // NOTE: This test will FAIL until AuthLoginView is fully implemented
        let service = AuthServiceStub()
        let viewModel = AuthViewModel(
            service: service,
            initialMode: .login,
            networkStatus: .wifi,
            onAuthenticated: { }
        )
        viewModel.errorMessage = "That email or password looks incorrect"
        
        // When navigationState is implemented:
        // viewModel.navigationState = .login
        
        let view = AuthLoginView(viewModel: viewModel)
        
        // This will fail with current placeholder view
        // assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
        
        // Temporary placeholder assertion
        XCTFail("AuthLoginView not fully implemented yet - snapshot will differ")
    }
    
    func testSignupViewWithPasswordMismatch() {
        // NOTE: This test will FAIL until AuthSignupView is fully implemented
        let service = AuthServiceStub()
        let viewModel = AuthViewModel(
            service: service,
            initialMode: .login,
            networkStatus: .wifi,
            onAuthenticated: { }
        )
        viewModel.errorMessage = "Passwords don't match"
        
        // When navigationState is implemented:
        // viewModel.navigationState = .signup(consentAccepted: false)
        
        let view = AuthSignupView(viewModel: viewModel)
        
        // This will fail with current placeholder view
        // assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
        
        // Temporary placeholder assertion
        XCTFail("AuthSignupView not fully implemented yet - snapshot will differ")
    }
}
