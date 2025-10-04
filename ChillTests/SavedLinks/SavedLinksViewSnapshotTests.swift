import SnapshotTesting
import SwiftUI
import XCTest
@testable import Chill

@MainActor
final class SavedLinksViewSnapshotTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        isRecording = false
    }

    func testAuthenticatedPlaceholderLayout() {
        let view = SavedLinksView()
        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
    }
}
