import SnapshotTesting
import SwiftUI
import XCTest
@testable import Chill

@MainActor
final class VideoCardSnapshotTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        isRecording = false
    }

    func test_cardLayout_notImplemented() {
        XCTFail("Video card snapshot tests not recorded yet")
    }
}
