//
//  ChillApp.swift
//  Chill
//
//  Created by Jin Budelmann on 10/4/25.
//

import SwiftUI
import SwiftData

@main
struct ChillApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for: VideoCardEntity.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
