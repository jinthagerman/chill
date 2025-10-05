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
    
    @StateObject private var viewModel = AddVideoViewModel()
    @Environment(\.dismiss) private var dismiss
    
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
    }
}

// MARK: - Preview

#Preview {
    AddVideoCoordinator()
}
