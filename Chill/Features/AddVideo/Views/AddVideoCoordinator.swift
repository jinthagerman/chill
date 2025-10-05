//
//  AddVideoCoordinator.swift
//  Chill
//
//  Created by Chill Team on 10/4/25.
//  Feature: 004-implement-add-video
//  Task: T052
//

import SwiftUI

/// Coordinates the two-step add video flow
struct AddVideoCoordinator: View {
    
    let authService: AuthService
    
    @StateObject private var viewModel: AddVideoViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    init(authService: AuthService) {
        self.authService = authService
        _viewModel = StateObject(wrappedValue: AddVideoViewModel(
            modelContext: nil, // Will be set from environment
            authService: authService
        ))
    }
    
    var body: some View {
        AddVideoInputView(viewModel: viewModel)
            .fullScreenCover(isPresented: $viewModel.isConfirmationPresented) {
                AddVideoConfirmationView(viewModel: viewModel)
            }
            .onChange(of: viewModel.isConfirmationPresented) { _, isPresented in
                // When confirmation screen is dismissed and metadata flow completes
                if !isPresented && viewModel.fetchedMetadata != nil {
                    // If we successfully saved, dismiss the entire flow
                    dismiss()
                }
            }
            .onAppear {
                // Inject ModelContext from environment
                if let context = try? modelContext {
                    // Update viewModel with context if needed
                }
            }
    }
}

// MARK: - Preview

#Preview {
    // Mock AuthService for preview
    let mockAuthService = AuthService(client: MockAuthClient())
    return AddVideoCoordinator(authService: mockAuthService)
}

// MARK: - Mock Auth Client for Preview

private class MockAuthClient: AuthServiceClient {
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
