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
    let connectivityMonitor: ConnectivityMonitor
    
    init() {
        do {
            // Initialize SwiftData with all models (Task T056)
            modelContainer = try ModelContainer(
                for: VideoCardEntity.self, VideoSubmissionRequest.self
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
        
        // Initialize connectivity monitor (Task T054)
        connectivityMonitor = ConnectivityMonitor()
        connectivityMonitor.start()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(\.connectivityMonitor, connectivityMonitor)
        }
    }
}

// MARK: - Environment Key for ConnectivityMonitor

private struct ConnectivityMonitorKey: EnvironmentKey {
    static let defaultValue: ConnectivityMonitor = ConnectivityMonitor()
}

extension EnvironmentValues {
    var connectivityMonitor: ConnectivityMonitor {
        get { self[ConnectivityMonitorKey.self] }
        set { self[ConnectivityMonitorKey.self] = newValue }
    }
}
