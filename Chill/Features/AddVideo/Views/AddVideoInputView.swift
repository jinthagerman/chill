//
//  AddVideoInputView.swift
//  Chill
//
//  Created by Chill Team on 10/4/25.
//  Feature: 004-implement-add-video
//  Tasks: T039-T045
//

import SwiftUI

/// Step 1: "Save a video" input modal
struct AddVideoInputView: View {
    
    @ObservedObject var viewModel: AddVideoViewModel
    @FocusState private var isURLFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title (Task T039)
            Text("Save a video")
                .font(.system(size: 28, weight: .bold))
                .padding(.top, 8)
            
            // URL Input Field (Task T040)
            VStack(alignment: .leading, spacing: 8) {
                TextField("Video URL", text: $viewModel.urlInput)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .focused($isURLFieldFocused)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Video URL")
                    .accessibilityHint("Enter video URL from Facebook or Twitter")
                
                // Error Message (Task T043)
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .transition(.opacity)
                }
                
                // Duplicate Warning (Task T043)
                if viewModel.isDuplicate {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Already in your library")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                    .transition(.opacity)
                }
            }
            
            // Description Field (Task T040)
            TextEditor(text: $viewModel.descriptionInput)
                .frame(minHeight: 120)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(alignment: .topLeading) {
                    if viewModel.descriptionInput.isEmpty {
                        Text("Description (optional)")
                            .foregroundColor(Color(.placeholderText))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
                .accessibilityLabel("Description")
                .accessibilityHint("Optional description for this video")
            
            Spacer()
            
            // Action Buttons (Task T041)
            HStack(spacing: 12) {
                // Cancel Button
                Button {
                    viewModel.cancelInput()
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                }
                .accessibilityLabel("Cancel, dismiss without saving")
                
                // Save Button
                Button {
                    viewModel.submitURL()
                } label: {
                    Text("Save")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(viewModel.isSaveButtonEnabled ? Color.black : Color.black.opacity(0.5))
                        .cornerRadius(12)
                }
                .disabled(!viewModel.isSaveButtonEnabled)
                .accessibilityLabel(viewModel.isSaveButtonEnabled ? "Save button" : "Save button, disabled")
                .accessibilityHint(viewModel.isSaveButtonEnabled ? "Fetch video details" : "Enter URL to enable")
            }
        }
        .padding(20)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.isLoading)
        .onAppear {
            isURLFieldFocused = true
        }
        .overlay {
            // Loading Overlay (Task T042)
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
    }
}

// MARK: - Loading Overlay (Task T042)

struct LoadingOverlay: View {
    @State private var showSlowMessage = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                if reduceMotion {
                    // Pulsing opacity instead of rotation
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .opacity(showSlowMessage ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(), value: showSlowMessage)
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                        .tint(.white)
                }
                
                Text(showSlowMessage ? "This is taking longer than usual..." : "Fetching video details...")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                showSlowMessage = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let mockAuthService = AuthService(client: MockAuthClientForInputPreview())
    let viewModel = AddVideoViewModel(authService: mockAuthService)
    return AddVideoInputView(viewModel: viewModel)
}

private class MockAuthClientForInputPreview: AuthServiceClient {
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
