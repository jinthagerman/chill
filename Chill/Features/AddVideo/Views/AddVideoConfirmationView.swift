//
//  AddVideoConfirmationView.swift
//  Chill
//
//  Created by Chill Team on 10/4/25.
//  Feature: 004-implement-add-video
//  Tasks: T046, T050, T051
//

import SwiftUI

/// Step 2: "Confirm Video" screen with preview and metadata
struct AddVideoConfirmationView: View {
    
    @ObservedObject var viewModel: AddVideoViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title (centered) - Task T046
                    Text("Confirm Video")
                        .font(.system(size: 22, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 16)
                    
                    if let metadata = viewModel.fetchedMetadata {
                        // Video Preview Card - Task T046, T047, T048
                        VideoPreviewCard(metadata: metadata)
                            .padding(.horizontal, 16)
                        
                        // Metadata Section - Task T046, T049
                        MetadataSection(metadata: metadata)
                            .padding(.horizontal, 16)
                        
                        Spacer()

                        if let errorMessage = viewModel.confirmationErrorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                        }

                        // Action Buttons - Task T050
                        VStack(spacing: 12) {
                            // Confirm and Save Button (Primary)
                            Button {
                                viewModel.confirmAndSave()
                            } label: {
                                Text("Confirm and Save")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(Color.black)
                                    .cornerRadius(12)
                            }
                            .disabled(viewModel.isLoading)
                            .accessibilityLabel("Confirm and save video to library")
                            
                            // Edit Details Button (Secondary)
                            Button {
                                viewModel.returnToEdit()
                            } label: {
                                Text("Edit Details")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(12)
                            }
                            .accessibilityLabel("Edit video details")
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            
            // Close Button (X) - Task T046
            Button {
                viewModel.closeConfirmation()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            .padding(.leading, 16)
            .padding(.top, 16)
            .accessibilityLabel("Close, dismiss without saving")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Confirm video details")
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let mockAuthService = AuthService(client: MockAuthClientPreview())
    let viewModel = AddVideoViewModel(authService: mockAuthService)
    viewModel.fetchedMetadata = VideoMetadata(
        title: "The Ultimate Guide to Productivity",
        videoDescription: nil,
        thumbnailURL: "https://via.placeholder.com/640x360",
        creator: "Productivity Pro",
        platform: .twitter,
        duration: 930, // 15:30
        publishedDate: nil,
        videoURL: "https://example.com/video.mp4",
        size: nil
    )
    
    return AddVideoConfirmationView(viewModel: viewModel) as AddVideoConfirmationView
}

private class MockAuthClientPreview: AuthServiceClient {
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
